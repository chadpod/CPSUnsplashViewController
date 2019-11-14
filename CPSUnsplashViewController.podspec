#
# Be sure to run `pod lib lint CPSUnsplashViewController.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'CPSUnsplashViewController'
  s.version          = '0.1.0'
  s.summary          = 'Unsplash Image Search'

  s.description      = <<-DESC
  Image search powered by the Unsplash API, with optional search keyword cloud and related tags support
                       DESC

  s.homepage         = 'https://github.com/chadpod/CPSUnsplashViewController'
  s.screenshots     = 'github.com/chadpod/CPSUnsplashViewController/Example/screenshots/unsplash-photo-grid.jpg', 'github.com/chadpod/CPSUnsplashViewController/Example/screenshots/unsplash-keyword-cloud.jpg'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Chad Podoski' => 'chadpod@me.com' }
  s.source           = { :git => 'https://github.com/chadpod/CPSUnsplashViewController.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/chadpod'

  s.ios.deployment_target = '11.0'

  s.source_files = 'CPSUnsplashViewController/Classes/**/*'
  
  s.frameworks = 'UIKit'
  s.dependency 'IGListKit'
  s.dependency 'DBSphereTagCloud'
end
