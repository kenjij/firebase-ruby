$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))
require 'firebase-ruby/version'


Gem::Specification.new do |s|
  s.name          = 'firebase-ruby'
  s.version       = Firebase::Version
  s.authors       = ['Ken J.']
  s.email         = ['kenjij@gmail.com']
  s.summary       = %q{Pure simple Ruby based Firebase REST library}
  s.description   = %q{Firebase REST library written in pure Ruby without external dependancy.}
  s.homepage      = 'https://github.com/kenjij/firebase-ruby'
  s.license       = 'MIT'

  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.require_paths = ['lib']
end
