Pod::Spec.new do |s|
  s.name         = 'POSJSONParsing'
  s.version      = '1.7.0'
  s.license      = 'MIT'
  s.summary      = 'Tiny wrapper around NSJSONSerialization to parse JSON with fluent API and detailed error reporting.'
  s.homepage     = 'https://github.com/pavelosipov/POSJSONParsing'
  s.author       = { 'Pavel Osipov' => 'posipov84@gmail.com' }
  s.source       = { :git => 'https://github.com/pavelosipov/POSJSONParsing.git', :tag => '1.7.0' }
  s.platform     = :ios, '6.0'
  s.requires_arc = true
  s.source_files = 'POSJSONParsing/*.{h,m}'
  s.frameworks   = 'Foundation'
end
