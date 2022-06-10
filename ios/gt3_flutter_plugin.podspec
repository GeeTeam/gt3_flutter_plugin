#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint gt3_flutter_plugin.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'gt3_flutter_plugin'
  s.version          = '0.0.8'
  s.summary          = 'The flutter plugin project for Geetest captcha.'
  s.description      = <<-DESC
  The flutter plugin project for Geetest captcha.
                       DESC
  s.homepage         = 'https://www.geetest.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Geetest' => 'xuwei@geetest.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.static_framework = true
  s.dependency 'Flutter'
  s.dependency 'GT3Captcha-iOS'
  s.platform = :ios, '9.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64 i386' }
  s.swift_version = '5.0'
end
