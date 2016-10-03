Pod::Spec.new do |s|
  s.name         = "Heft"
  s.summary      = "Heft Library"
  s.description  = "Handpoint SDK for iOS"
  s.homepage     = "https://github.com/handpoint/Handpoint-iOS-SDK"
  s.license      = "To be continued"
  s.author       = { "Handpoint" => "email.not.published@mailinator.com" }
  s.version      = "2.4.0"
  s.source       = { :git => "https://github.com/handpoint/Handpoint-iOS-SDK.git"}
  s.platform     = :ios, '7.0'
  s.ios.deployment_target = '7.0'
  s.requires_arc = true
  s.source_files = "heft/*.{h,m}", "heft/*.mm", "heft/shared/*.{h,m}", "heft/shared/*.mm", "heft/shared/api/CmdIds.h"
  s.public_header_files = "heft/*.h", "heft/Shared/*.h"
  # s.prefix_header_file = 'heft/heft-Prefix.pch'

#  s.private_header_files = "heft/shared/*.h"
#  s.ios.vendored_frameworks = 'ExternalAccessory.framework'
end
