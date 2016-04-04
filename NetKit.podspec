Pod::Spec.new do |s|
s.name             = "NetKit"
s.version          = "0.9.2.5"
s.summary          = "A Concise HTTP Framework in Swift."
s.description      = "A Concise and Easy To Use HTTP Framework in Swift."
s.homepage         = "https://github.com/azizuysal/NetKit"
s.license          = 'MIT'
s.author           = { "azizuysal" => "azizuysal@gmail.com" }
s.source           = { :git => "https://github.com/azizuysal/NetKit.git", :tag => s.version.to_s }
s.platform         = :ios, '8.0'
s.requires_arc     = true

# If more than one source file: https://guides.cocoapods.org/syntax/podspec.html#source_files
s.source_files = 'NetKit/NetKit/*.{swift}'

end
