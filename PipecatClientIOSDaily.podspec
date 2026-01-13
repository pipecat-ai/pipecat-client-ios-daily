Pod::Spec.new do |s|
  s.name         = 'PipecatClientIOSDaily'
  s.version      = '1.2.0'
  s.summary      = 'Pipecat iOS client library with Daily WebRTC transport.'
  s.description  = <<-DESC
                    The Daily transport implementation enables real-time audio and video communication in your Pipecat iOS applications using Daily’s WebRTC infrastructure.
                   DESC
  s.homepage     = 'https://github.com/pipecat-ai/pipecat-client-ios-daily'
  s.documentation_url  = "https://docs.pipecat.ai/client/ios/introduction"
  s.license      = { :type => 'BSD-2', :file => 'LICENSE' }
  s.author             = { "Daily.co" => "help@daily.co" }
  s.source       = { :git => 'https://github.com/pipecat-ai/pipecat-client-ios-daily.git', :tag => "1.2.0" }
  s.ios.deployment_target = '13.0'
  s.source_files = 'Sources/**/*.{swift,h,m}'
  s.exclude_files = 'Sources/Exclude'
  s.swift_version = '5.5'
  # Dependencies
  s.dependency 'PipecatClientIOS', '~> 1.2.0'
  s.dependency 'Daily', '~> 0.35.0'
end
