import Foundation
import PipecatClientIOS

// MARK: - Track Change Detection
extension DailyTransport {

    func handleTrackChanges(previous: Tracks, current: Tracks) {
        // Local participant changes
        compareParticipantTracks(
            previous: previous.local,
            current: current.local,
            participant: nil  // Local participant
        )

        // Bot participant changes
        compareParticipantTracks(
            previous: previous.bot,
            current: current.bot,
            participant: self.botUser
        )
    }

    func handleInitialTracks(tracks: Tracks) {
        // Notify for local tracks
        notifyParticipantTracksStarted(tracks: tracks.local, participant: nil)

        // Notify for bot tracks
        if let botTracks = tracks.bot {
            notifyParticipantTracksStarted(tracks: botTracks, participant: self.botUser)
        }
    }

    private func compareParticipantTracks(
        previous: ParticipantTracks?,
        current: ParticipantTracks?,
        participant: Participant?
    ) {
        let prev = previous ?? ParticipantTracks(audio: nil, video: nil, screenAudio: nil, screenVideo: nil)
        let curr = current ?? ParticipantTracks(audio: nil, video: nil, screenAudio: nil, screenVideo: nil)

        // Check audio track changes
        compareTrack(
            previous: prev.audio,
            current: curr.audio,
            participant: participant,
            isScreen: false
        )

        // Check video track changes
        compareTrack(
            previous: prev.video,
            current: curr.video,
            participant: participant,
            isScreen: false
        )

        // Check screen audio track changes
        compareTrack(
            previous: prev.screenAudio,
            current: curr.screenAudio,
            participant: participant,
            isScreen: true
        )

        // Check screen video track changes
        compareTrack(
            previous: prev.screenVideo,
            current: curr.screenVideo,
            participant: participant,
            isScreen: true
        )
    }

    private func compareTrack(
        previous: MediaStreamTrack?,
        current: MediaStreamTrack?,
        participant: Participant?,
        isScreen: Bool
    ) {
        // Track stopped (was present, now absent)
        if let prevTrack = previous, current == nil {
            if isScreen {
                delegate?.onScreenTrackStopped(track: prevTrack, participant: participant)
            } else {
                delegate?.onTrackStopped(track: prevTrack, participant: participant)
            }
        }

        // Track started (was absent, now present)
        if previous == nil, let currTrack = current {
            if isScreen {
                delegate?.onScreenTrackStarted(track: currTrack, participant: participant)
            } else {
                delegate?.onTrackStarted(track: currTrack, participant: participant)
            }
        }

        // Track changed (different track IDs)
        if let prevTrack = previous,
            let currTrack = current,
            prevTrack.id != currTrack.id {
            // Stop the old track and start the new one
            if isScreen {
                delegate?.onScreenTrackStopped(track: prevTrack, participant: participant)
                delegate?.onScreenTrackStarted(track: currTrack, participant: participant)
            } else {
                delegate?.onTrackStopped(track: prevTrack, participant: participant)
                delegate?.onTrackStarted(track: currTrack, participant: participant)
            }
        }
    }

    private func notifyParticipantTracksStarted(tracks: ParticipantTracks, participant: Participant?) {
        if let audioTrack = tracks.audio {
            delegate?.onTrackStarted(track: audioTrack, participant: participant)
        }

        if let videoTrack = tracks.video {
            delegate?.onTrackStarted(track: videoTrack, participant: participant)
        }

        if let screenAudioTrack = tracks.screenAudio {
            delegate?.onScreenTrackStarted(track: screenAudioTrack, participant: participant)
        }

        if let screenVideoTrack = tracks.screenVideo {
            delegate?.onScreenTrackStarted(track: screenVideoTrack, participant: participant)
        }
    }
}
