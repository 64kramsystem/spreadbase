$LOAD_PATH.push(File.expand_path("../lib", __FILE__))

require "spreadbase/version"

Gem::Specification.new do |s|
  s.name        = "spreadbase"
  s.version     = SpreadBase::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Saverio Miroddi"]
  s.email       = ["saverio.pub2@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Library for reading/writing OpenOffice Calc documents.}
  s.description = %q{Library for reading/writing OpenOffice Calc documents.}

  s.add_runtime_dependency     "zipruby", "~>0.3.6"
  s.add_development_dependency "rspec",   "~>2.9.0"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {spec,temp,utils}/*`.split("\n")
  s.executables   = []
  s.require_paths = ["lib"]
end
