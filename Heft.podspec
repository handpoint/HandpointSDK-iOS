Pod::Spec.new do |s|
  s.name         = "Heft"
  s.summary      = "Heft Library"
  s.description  = ""
  s.homepage     = "https://github.com/handpoint/Handpoint-iOS-SDK"
  s.license      = ""
  s.author       = { "Handpoint" => "email.not.published@mailinator.com" }
  s.version      = "2.4.0"
  s.source       = { :git => "https://github.com/handpoint/Handpoint-iOS-SDK.git"}
  s.platform     = :ios, '5.0'
  s.requires_arc = true
  s.source_files = "heft/*.{h,m}"

end
