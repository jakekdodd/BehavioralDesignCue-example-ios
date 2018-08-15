#
# Be sure to run `pod lib lint BehavioralDesignCue.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'BehavioralDesignCue'
  s.version          = '0.1.0'
  s.summary          = 'An implementation for labeling Behavioral Design Cues for App Opens. Cues like notifications, shortcuts, and deep links are categorized into synthetic, internal, and external cues.'
  s.description      = <<-DESC
  An implementation for labeling Behavioral Design Cues for App Opens. Cues like notifications, shortcuts, and deep links are categorized into synthetic, internal, and external cues. The eBook Digital Behavioral Design (https://www.boundless.ai/ebook/) goes into more detail on what cues are and how they affect users.
                       DESC

  s.homepage         = 'https://www.boundless.ai'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'boundlessai' => 'team@boundless.ai' }
  s.source           = { :git => 'https://github.com/BoundlessAI/BehavioralDesignCue-example-ios.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/boundlessai'

  s.ios.deployment_target = '8.0'

  s.source_files = 'BehavioralDesignCue/Classes/**/*'
  
end
