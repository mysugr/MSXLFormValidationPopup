Pod::Spec.new do |s|
  s.name             = 'MSXLFormValidationPopup'
  s.version          = '0.1.0'
  s.summary          = 'A little validation popup for your XLForms.'
  s.description      = <<-DESC
A small add-on for XLForm that shows a validation popup with error information on top of fields.
                       DESC

  s.homepage         = 'https://github.com/mysugr/MSXLFormValidationPopup'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Bernhard Schandl' => 'bernhard.schandl@mysugr.com' }
  s.source           = { :git => 'https://github.com/mysugr/MSXLFormValidationPopup.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/mysugr'

  s.ios.deployment_target = '9.3'

  s.source_files = 'MSXLFormValidationPopup/Classes/*.{h,m}'

  s.dependency 'XLForm', '3.2.0'
  s.dependency 'JGMethodSwizzler', '2.0.1'
  
end
