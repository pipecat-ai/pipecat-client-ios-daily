# Pipecat iOS SDK with Daily Transport

The [Pipecat](https://github.com/pipecat-ai/) project uses [RTVI-AI](https://docs.pipecat.ai/client/introduction), an open standard for Real-Time Voice [and Video] Inference.

This library exports a VoiceClient that has the [Daily](https://www.daily.co/) transport associated.

## Install

To depend on the client package, you can add this package via Xcode's package manager using the URL of this git repository directly, or you can declare your dependency in your `Package.swift`:

```swift
.package(url: "https://github.com/pipecat-ai/pipecat-client-ios-daily.git", from: "1.1.0"),
```

and add `"PipecatClientIOSDaily"` to your application/library target, `dependencies`, e.g. like this:

```swift
.target(name: "YourApp", dependencies: [
    .product(name: "PipecatClientIOSDaily", package: "pipecat-client-ios-daily")
],
```

## Quick Start

Instantiate a `VoiceClient` instance, wire up the bot's audio, and start the conversation:

```swift
let pipecatClientOptions = PipecatClientOptions.init(
    transport: DailyTransport.init(),
    enableMic: true,
    enableCam: false,
)
let pipecatClientIOS = PipecatClient.init(
    options: pipecatClientOptions
)
let startBotParams = APIRequest.init(endpoint: URL(string: baseUrl + "/connect")!)
pipecatClientIOS?.startBotAndConnect(startBotParams: startBotParams) { (result: Result<DailyTransportConnectionParams, AsyncExecutionError>) in
    switch result {
    case .failure(let error):
        // Handle error
    case .success(_):
        // handle success
    }
}
```

## References
- [pipecat-client-ios reference docs](https://docs-ios.pipecat.ai/PipecatClientIOS/documentation/pipecatclientios).
- [pipecat-client-ios SDK docs](https://docs.pipecat.ai/client/ios/introduction).
- [SimpleChatbot example](https://github.com/pipecat-ai/pipecat-examples/tree/main/simple-chatbot/client/ios).

## Contributing

We are welcoming contributions to this project in form of issues and pull request. For questions about Pipecat Client head over to the [Pipecat discord server](https://discord.gg/pipecat).
