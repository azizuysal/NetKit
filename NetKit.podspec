Pod::Spec.new do |s|
s.name             = "NetKit"
s.version          = "0.9.5.0"
s.summary          = "A Concise HTTP Framework in Swift."
s.description      = "A Concise and Easy To Use HTTP Framework in Swift."
s.homepage         = "https://github.com/azizuysal/NetKit"
s.license          = { :type => "MIT", :file => "LICENSE.md" }
s.author           = { "Aziz Uysal" => "azizuysal@gmail.com" }
s.social_media_url = 'https://twitter.com/azizuysal'
s.source           = { :git => "https://github.com/azizuysal/NetKit.git", :tag => s.version.to_s }
s.platform         = :ios, '10.0'
s.requires_arc     = true

# If more than one source file: https://guides.cocoapods.org/syntax/podspec.html#source_files
s.source_files = 'NetKit/NetKit/*.{swift}'

end
