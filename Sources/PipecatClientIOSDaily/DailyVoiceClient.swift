import Foundation
import PipecatClientIOS

/// An RTVI client. Connects to a Daily Bots backend and handles bidirectional audio and video streaming
@MainActor
public class DailyVoiceClient: RTVIClient {
    
    public init(baseUrl:String? = nil, options: RTVIClientOptions) {
        if baseUrl == nil && options.params.baseUrl == nil {
            print("DailyVoiceClient will not work without a baseUrl specified")
        }
        super.init(baseUrl: baseUrl, transport: DailyTransport.init(options: options), options: options)
    }
    
}
