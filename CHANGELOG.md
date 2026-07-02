# Unreleased

### Fixed

- Fixed a memory leak in `DailyTransport`. `voiceClientOptions` (set in `initialize(options:)`) holds a reference to `options.transport`, which is the `DailyTransport` instance itself — a self-retain cycle (`DailyTransport → voiceClientOptions → transport → DailyTransport`). `release()` cleared `callClient` but never `voiceClientOptions`, so the cycle was never broken and every connect/disconnect cycle leaked a `DailyTransport` instance. `release()` now also clears `voiceClientOptions`. ([#27](https://github.com/pipecat-ai/pipecat-client-ios-daily/issues/27))

# 1.2.0 — 2026-01-13

### Changed

- Updated the `PipecatClientIOS` dependency to [1.2.0](https://github.com/pipecat-ai/pipecat-client-ios/blob/main/CHANGELOG.md#120--2026-01-03).

# 1.1.3 — 2025-12-11

### Fixed

- Fixed a memory leak in `DailyTransport`: `localAudioLevelProcessor` and `botAudioLevelProcessor` captured `self` strongly, keeping the transport (and its `CallClient`) retained after disconnect.
- Updated the `PipecatClientIOS` dependency to [1.1.3](https://github.com/pipecat-ai/pipecat-client-ios/blob/main/CHANGELOG.md#113--2025-12-11), which fixes a related memory leak in `PipecatClient` itself (its `onMessage` closure also captured `self` strongly, preventing `PipecatClient` from ever being deallocated).

# 1.1.2 — 2025-10-28

### Changed

- Updated the `PipecatClientIOS` dependency to [1.1.2](https://github.com/pipecat-ai/pipecat-client-ios/blob/main/CHANGELOG.md#112--2025-10-28).

# 1.1.0 — 2025-10-14

### Changed

- Updated the `PipecatClientIOS` dependency to [1.1.0](https://github.com/pipecat-ai/pipecat-client-ios/blob/main/CHANGELOG.md#110--2025-10-14).

# 1.0.1 — 2025-09-19

### Changed

- Updated the `PipecatClientIOS` dependency to [1.0.1](https://github.com/pipecat-ai/pipecat-client-ios/blob/main/CHANGELOG.md#101---2025-09-19).

# 1.0.0 — 2025-08-25

### Changed

- Updated the `PipecatClientIOS` dependency to [1.0.0](https://github.com/pipecat-ai/pipecat-client-ios/blob/main/CHANGELOG.md#100---2025-08-25), following the RTVI/Pipecat protocol rewrite.

# 0.3.7 — 2025-08-12

### Added

- Allowed the `token` to be `nil`.
- Added support for different variations of `roomUrl` and `token`.

# 0.3.6 — 2025-06-11

### Added

- Exposed the underlying Daily `CallClient` via a public getter on `DailyTransport`.

### Changed

- Updated the `PipecatClientIOS` dependency to [0.3.6](https://github.com/pipecat-ai/pipecat-client-ios/blob/main/CHANGELOG.md#036---2025-06-11).

# 0.3.2 — 2025-01-15

### Changed

- Renamed the target to `PipecatClientIOSDaily` (from `RTVIClientIOSDaily`) and added CocoaPods support.
- Updated the `PipecatClientIOS` dependency to [0.3.2](https://github.com/pipecat-ai/pipecat-client-ios/blob/main/CHANGELOG.md#032---2025-01-15).

# 0.3.1 — 2025-01-08

### Changed

- Updated the `PipecatClientIOS` dependency to [0.3.1](https://github.com/pipecat-ai/pipecat-client-ios/blob/main/CHANGELOG.md#031---2025-01-03).

# 0.3.0 — 2024-12-10

### Changed

- Renamed the package from `RTVIClientIOSDaily` to `PipecatClientIOSDaily`.

# 0.2.0 — 2024-10-10

### Changed

- Updated to track the `RTVIClientIOS` 0.2.0 rename and API changes (`VoiceClient` → `RTVIClient`, `params.baseUrl`/`params.config`/`params.headers`, etc).

# 0.1.0 – 0.1.8 — 2024-08-16 to 2024-09-16

Initial development releases, tracking the `rtvi-client-ios` dependency:

- Sent a message to the bot when the client is ready.
- Fixed a bundle issue where `roomName` was expected but not always present.
- Added support for custom body params.
- Added a `VoiceClientVideoView` wrapper for SwiftUI, camera support, an `onTracksUpdated` event, and exposed room expiry.
- Updated `swift-tools-version` to 5.5.
