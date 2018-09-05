Pod::Spec.new do |s|
  s.name         = "HandpointSDK"
  s.version      = "3.1.6"
  s.summary      = "Handpoint SDK for iOS"
  s.description  = <<-DESC
                    For detailed information, please see Handpoint documentation and Readme in https://www.handpoint.com/docs/device/iOS/
                   DESC
  s.homepage     = "https://www.handpoint.com/docs/device/iOS/"
  s.license      = { :type => 'Commercial', :file => 'LICENSE' }
  s.author       = { "Handpoint" => "hi@handpoint.com" }
  s.source       = { :git => "https://github.com/handpoint/Handpoint-iOS-SDK.git", :tag => "#{s.version}"}
  s.platform     = :ios, '8.0'
  s.source_files = 'heft/**/*.{h,m}', 'heft/**/*.mm'
  s.public_header_files = 'heft/Shared/api/*.h' 
  s.framework = 'ExternalAccessory'
  s.library   = 'z', 'c++'
  s.xcconfig  =  { 'OTHER_LDFLAGS' => '-ObjC -lc++'}
end