#
# Be sure to run `pod lib lint ConnectSDK-CompanionLibrary-iOS.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "ConnectSDK-CompanionLibrary-iOS"
  s.version          = "0.1.0"
  s.summary          = "iOS library for adding ConnectSDK cast features to existing apps."

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!
  s.description      = <<-DESC
                        is a library project to enable developers integrate LG's ConnectSDK casting capabilities into their applications more easily
                       DESC

  s.homepage         = "https://github.com/gomino/ConnectSDK-CompanionLibrary-iOS"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'Apache License, Version 2.0'
  s.author           = { "Amine Bezzarga" => "abezzarg@gmail.com" }
  s.source           = { :git => "https://github.com/gomino/ConnectSDK-CompanionLibrary-iOS.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/go_mino'

  s.platform     = :ios, '7.0'
  s.requires_arc = false

#s.resources = 'Pod/Classes/Cast/CastUI/*.xib'
#s.resources = 'Pod/Assets/*.png'
#s.resource = 'Pod/Classes/**/*.{xib}'
  s.source_files = 'Pod/Classes/**/*.{h,m}'
  s.resource_bundles = {
    #'ConnectSDK-CompanionLibrary-iOS' => ['Pod/Assets/Images.xcassets', 'Pod/Classes/**/*.xib']
    'ConnectSDK-CompanionLibrary-iOS' => ['Pod/Assets/*.png', 'Pod/Classes/**/*.xib']
    #'ConnectSDK-CompanionLibrary-iOS' => ['Pod/Classes/**/*.{xib}']
  }

  s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'ConnectSDK/Core' , '~> 1.4.2'
  s.dependency 'AsyncImageView' , '~> 1.5.1'
  s.dependency 'Masonry'
end
