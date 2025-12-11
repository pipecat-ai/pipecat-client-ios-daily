import Foundation
import PipecatClientIOS
import Daily

/// An RTVI transport to connect with Daily.
public class DailyTransport: Transport {
    private var callClient: CallClient?
    /// Expose the underlying Daily CallClient for direct SDK interaction (e.g. zoom, torch).
    public var dailyCallClient: CallClient? {
        return self.callClient
    }
    private var voiceClientOptions: PipecatClientIOS.PipecatClientOptions?

    private var devicesInitialized: Bool = false
    var botUser: PipecatClientIOS.Participant?
    private var _selectedCam: MediaDeviceInfo?
    private var _selectedMic: MediaDeviceInfo?
    private var clientReady: Bool = false
    private var _tracks: Tracks?

    // callback
    public var onMessage: ((RTVIMessageInbound) -> Void)?

    /// The object that acts as the delegate of the voice client.
    public weak var delegate: PipecatClientDelegate?
    private var _state: TransportState = .disconnected

    private lazy var localAudioLevelProcessor = AudioLevelProcessor { [weak self] isSpeaking in
        if isSpeaking {
            self?.delegate?.onUserStartedSpeaking()
        } else {
            self?.delegate?.onUserStoppedSpeaking()
        }
    }

    // For the bot, when it is not speaking it looks like we always receive "0"
    private lazy var botAudioLevelProcessor = AudioLevelProcessor(threshold: 0.001) { [weak self] isSpeaking in
        if isSpeaking {
            self?.delegate?.onBotStartedSpeaking()
        } else {
            self?.delegate?.onBotStoppedSpeaking()
        }
    }

    required public init() {
        self.callClient = CallClient()
        self.callClient?.delegate = self
    }

    public func initialize(options: PipecatClientOptions) {
        self.voiceClientOptions = options
    }

    func updateBotUserAndTracks() {
        self.botUser = self.callClient?.participants.remote.first?.value.toRtvi()
        guard let currentTracks = self.tracks() else {
            // Nothing to do here, no tracks available yet
            return
        }

        if let previousTracks = self._tracks {
            self.handleTrackChanges(previous: previousTracks, current: currentTracks)
        } else {
            // First time tracks are available, notify all starting tracks
            self.handleInitialTracks(tracks: currentTracks)
        }

        self._tracks = currentTracks
    }

    public func initDevices() async throws {
        if self.devicesInitialized {
            // There is nothing to do in this case
            return
        }
        self.setState(state: .initializing)

        // trigger the initial status
        self.delegate?.onAvailableCamsUpdated(cams: self.getAllCams())
        self.delegate?.onAvailableMicsUpdated(mics: self.getAllMics())
        self._selectedCam = self.selectedCam()
        self.delegate?.onCamUpdated(cam: self._selectedCam)
        self._selectedMic = self.selectedMic()
        self.delegate?.onMicUpdated(mic: self._selectedMic)

        self.callClient?.startLocalAudioLevelObserver(intervalMs: 100, completion: nil)
        self.callClient?.startRemoteParticipantsAudioLevelObserver(intervalMs: 100, completion: nil)

        self.setState(state: .initialized)
        self.devicesInitialized = true
    }

    public func connect(transportParams: TransportConnectionParams?) async throws {
        self.setState(state: .connecting)

        guard let dailyParams = transportParams as? DailyTransportConnectionParams else {
            throw InvalidTransportParamsError()
        }

        guard let roomURL = URL(string: dailyParams.roomUrl) else {
            throw InvalidTransportParamsError()
        }

        let meetingToken: MeetingToken? = {
            if let token = dailyParams.token {
                MeetingToken(stringValue: token)
            } else {
                nil
            }
        }()

        let joinSettings: ClientSettingsUpdate
        if let _joinSetting = dailyParams.joinSettings {
            joinSettings = _joinSetting.mergingCameraAndMicrophoneSettings(
                enableCam: voiceClientOptions!.enableCam,
                enableMic: voiceClientOptions!.enableMic
            )
        } else {
            joinSettings = ClientSettingsUpdate(
                inputs: .set(
                    camera: .set(
                        isEnabled: .set(voiceClientOptions!.enableCam)
                    ),
                    microphone: .set(
                        isEnabled: .set(voiceClientOptions!.enableMic)
                    )
                )
            )
        }
        try await self.callClient?.join(url: roomURL, token: meetingToken, settings: joinSettings)
    }

    public func disconnect() async throws {
        try await self.callClient?.stopLocalAudioLevelObserver()
        try await self.callClient?.stopRemoteParticipantsAudioLevelObserver()
        try await self.callClient?.leave()
        self.devicesInitialized = false
        self._selectedCam = nil
        self._selectedMic = nil
    }

    public func getAllMics() -> [PipecatClientIOS.MediaDeviceInfo] {
        self.callClient?.availableDevices.microphone.compactMap { $0.toRtvi() } ?? []
    }

    public func getAllCams() -> [PipecatClientIOS.MediaDeviceInfo] {
        self.callClient?.availableDevices.camera.compactMap { $0.toRtvi() } ?? []
    }

    public func updateMic(micId: PipecatClientIOS.MediaDeviceId) async throws {
        try await self.callClient?.setPreferredAudioDevice(AudioDeviceType.init(deviceID: micId.id))
    }

    public func updateCam(camId: PipecatClientIOS.MediaDeviceId) async throws {
        _ = try await self.callClient?
            .updateInputs(
                .set(
                    InputSettingsUpdate(
                        camera: .set(
                            CameraInputSettingsUpdate(
                                settings: .set(
                                    VideoMediaTrackSettingsUpdate(
                                        deviceID: .set(MediaTrackDeviceID(camId.id))
                                    )
                                )
                            )
                        )
                    )
                )
            )
    }

    public func selectedMic() -> PipecatClientIOS.MediaDeviceInfo? {
        guard let deviceId = self.callClient?.inputs.microphone.settings.deviceID else {
            return nil
        }
        return self.getAllMics().first { $0.id.id == deviceId }
    }

    public func selectedCam() -> PipecatClientIOS.MediaDeviceInfo? {
        guard let deviceId = self.callClient?.inputs.camera.settings.deviceID else {
            return nil
        }
        return self.getAllCams().first { $0.id.id == deviceId }
    }

    public func enableMic(enable: Bool) async throws {
        try await self.callClient?.setInputsEnabled([.microphone: enable])
    }

    public func enableCam(enable: Bool) async throws {
        try await self.callClient?.setInputsEnabled([.camera: enable])
    }

    public func isCamEnabled() -> Bool {
        self.callClient?.inputs.camera.isEnabled ?? false
    }

    public func isMicEnabled() -> Bool {
        self.callClient?.inputs.microphone.isEnabled ?? false
    }

    public func sendMessage(message: PipecatClientIOS.RTVIMessageOutbound) throws {
        let messageToSend = try JSONEncoder().encode(message)
        // For testing only
        // print("Sending app message \(String(data: messageToSend, encoding: .utf8))")
        self.callClient?.sendAppMessage(json: messageToSend, to: .all, completion: nil)
    }

    public func state() -> PipecatClientIOS.TransportState {
        self._state
    }

    public func setState(state: PipecatClientIOS.TransportState) {
        if state == .connected && self._state == .ready {
            // Sometimes we are receiving the ready state from the bot even before we receive the connected state
            // So, since the ready should be the last state, we are just ignoring it for now
            return
        }
        self._state = state
        self.delegate?.onTransportStateChanged(state: self._state)
    }

    public func tracks() -> PipecatClientIOS.Tracks? {
        guard let callClient = self.callClient else {
            return nil
        }
        let participants = callClient.participants

        let local = participants.local
        let bot = participants.all.values.first { !$0.info.isLocal }

        VideoTrackRegistry.clearRegistry()

        let localVideoTrack = local.media?.camera.track?.toRtvi()
        // Registering the track so we can retrieve it later inside the VoiceClientVideoView
        if let localVideoTrack = localVideoTrack {
            VideoTrackRegistry.registerTrack(
                originalTrack: local.media!.camera.track!,
                mediaTrackId: localVideoTrack.id
            )
        }
        let localScreenVideoTrack = local.media?.screenVideo.track?.toRtvi()
        // Registering the track so we can retrieve it later inside the VoiceClientVideoView
        if let localScreenVideoTrack = localScreenVideoTrack {
            VideoTrackRegistry.registerTrack(
                originalTrack: local.media!.screenVideo.track!,
                mediaTrackId: localScreenVideoTrack.id
            )
        }

        let botVideoTrack = bot?.media?.camera.track?.toRtvi()
        // Registering the track so we can retrieve it later inside the VoiceClientVideoView
        if let botVideoTrack = botVideoTrack {
            VideoTrackRegistry.registerTrack(originalTrack: bot!.media!.camera.track!, mediaTrackId: botVideoTrack.id)
        }
        let botScreenVideoTrack = bot?.media?.screenVideo.track?.toRtvi()
        // Registering the track so we can retrieve it later inside the VoiceClientVideoView
        if let botScreenVideoTrack = botScreenVideoTrack {
            VideoTrackRegistry.registerTrack(
                originalTrack: bot!.media!.screenVideo.track!,
                mediaTrackId: botScreenVideoTrack.id
            )
        }

        return Tracks(
            local: ParticipantTracks(
                audio: local.media?.microphone.track?.toRtvi(),
                video: localVideoTrack,
                screenAudio: local.media?.screenAudio.track?.toRtvi(),
                screenVideo: localScreenVideoTrack
            ),
            bot: ParticipantTracks(
                audio: bot?.media?.microphone.track?.toRtvi(),
                video: botVideoTrack,
                screenAudio: bot?.media?.screenAudio.track?.toRtvi(),
                screenVideo: botScreenVideoTrack
            )
        )
    }

    public func release() {
        VideoTrackRegistry.clearRegistry()
        // It should automatically trigger deinit inside CallClient
        self.callClient = nil
    }

}

extension DailyTransport: CallClientDelegate {

    public func callClient(_ callClient: CallClient, participantJoined participant: Daily.Participant) {
        self.delegate?.onParticipantJoined(participant: participant.toRtvi())
        self.updateBotUserAndTracks()
        if !participant.info.isLocal && self.botUser != nil {
            self.delegate?.onBotConnected(participant: self.botUser!)
        }
    }

    public func callClient(_ callClient: CallClient, participantUpdated participant: Daily.Participant) {
        self.updateBotUserAndTracks()
        if !self.clientReady && !participant.info.isLocal && participant.media?.microphone.state == .playable {
            self.clientReady = true
            do {
                try self.sendMessage(message: RTVIMessageOutbound.clientReady())
            } catch {
                self.delegate?
                    .onError(message: .errorMessage(error: "Failed to send message that the client is ready \(error)"))
            }
        }
    }

    public func callClient(
        _ callClient: CallClient,
        participantLeft participant: Daily.Participant,
        withReason reason: ParticipantLeftReason
    ) {
        self.delegate?.onParticipantLeft(participant: participant.toRtvi())
        self.updateBotUserAndTracks()
        if !participant.info.isLocal && self.botUser == nil {
            self.delegate?.onBotDisconnected(participant: participant.toRtvi())
        }
    }

    public func callClient(_ callClient: Daily.CallClient, localAudioLevel audioLevel: Float) {
        // We are using the events that we receive from the bot for this case, since it seems more reliable
        // self.localAudioLevelProcessor.onLevelChanged(level: audioLevel)
        self.delegate?.onLocalAudioLevel(level: audioLevel)
    }

    public func callClient(
        _ callClient: Daily.CallClient,
        remoteParticipantsAudioLevel participantsAudioLevel: [Daily.ParticipantID: Float]
    ) {
        participantsAudioLevel.forEach { id, level in
            let rtviId = id.toRtvi()
            if botUser?.id == rtviId {
                self.botAudioLevelProcessor.onLevelChanged(level: level)
                self.delegate?.onRemoteAudioLevel(level: level, participant: botUser!)
            }
        }
    }

    public func callClient(_ callClient: CallClient, appMessageAsJson jsonData: Data, from participantID: ParticipantID) {
        do {
            // For testing only
            // print("Received app message \(String(data: jsonData, encoding: .utf8))")
            let appMessage = try JSONDecoder()
                .decode(
                    RTVIMessageInbound.self,
                    from: jsonData
                )
            self.onMessage?(appMessage)
        } catch {
            // Ignoring it, not an RTVI message
        }
    }

    public func callClient(_ callClient: CallClient, callStateUpdated state: CallState) {
        if state == .left {
            self.setState(state: .disconnected)
            self.delegate?.onDisconnected()
            self.clientReady = false
        } else if state == .joined {
            if self.state() != .disconnecting {
                self.setState(state: .connected)
                self.delegate?.onConnected()
            }
        }
    }

    public func callClient(_ callClient: CallClient, availableDevicesUpdated availableDevices: Devices) {
        self.delegate?.onAvailableCamsUpdated(cams: self.getAllCams())
        self.delegate?.onAvailableMicsUpdated(mics: self.getAllMics())
        self.delegate?.onAvailableSpeakersUpdated(speakers: self.getAllMics())
    }

    public func callClient(_ callClient: CallClient, inputsUpdated inputs: InputSettings) {
        if self.selectedCam() != self._selectedCam {
            self._selectedCam = self.selectedCam()
            self.delegate?.onCamUpdated(cam: self._selectedCam)
        }
        if self.selectedMic() != self._selectedMic {
            self._selectedMic = self.selectedMic()
            self.delegate?.onMicUpdated(mic: self._selectedMic)
            self.delegate?.onSpeakerUpdated(speaker: self._selectedMic)
        }
    }

}
