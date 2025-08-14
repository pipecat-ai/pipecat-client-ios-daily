import Foundation
import PipecatClientIOS
import Daily

extension Daily.AudioTrack {
    func toRtvi() -> PipecatClientIOS.MediaStreamTrack {
        return MediaStreamTrack(
            id: MediaTrackId(id: id),
            kind: .audio
        )
    }
}

extension Daily.VideoTrack {
    func toRtvi() -> PipecatClientIOS.MediaStreamTrack {
        return MediaStreamTrack(
            id: MediaTrackId(id: id),
            kind: .video
        )
    }
}

extension Daily.ParticipantID {
    func toRtvi() -> PipecatClientIOS.ParticipantId {
        return PipecatClientIOS.ParticipantId(
            id: self.uuidString
        )
    }
}

extension Daily.Participant {
    func toRtvi() -> PipecatClientIOS.Participant {
        return PipecatClientIOS.Participant(
            id: self.id.toRtvi(),
            name: self.info.username,
            local: self.info.isLocal
        )
    }
}

extension Daily.Device {
    func toRtvi() -> PipecatClientIOS.MediaDeviceInfo {
        return PipecatClientIOS.MediaDeviceInfo(id: MediaDeviceId(id: self.deviceID), name: self.label)
    }
}
