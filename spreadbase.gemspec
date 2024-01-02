# frozen_string_literal: true

$LOAD_PATH.push(File.expand_path("../lib", __FILE__))

require "spreadbase/version"

Gem::Specification.new do |s|
  s.name        = "spreadbase"
  s.version     = SpreadBase::VERSION
  s.platform    = Gem::Platform::RUBY
  s.required_ruby_version = '>= 3.0.0'
  s.authors     = ["Saverio Miroddi"]
  s.date        = '2021-12-31'
  s.email       = ["saverio.pub2@gmail.com"]
  s.homepage    = "https://github.com/saveriomiroddi/spreadbase"
  s.summary     = %q{Library for reading/writing OpenOffice Calc documents.}
  s.description = %q{Library for reading/writing OpenOffice Calc documents.}
  s.license     = "GPL-3.0"

  s.add_runtime_dependency     "rubyzip", ">=2.3.0"
  s.add_development_dependency "rspec",   "~>3.12.0"

  s.add_development_dependency "rake",   "~>13.0"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {spec,temp,utils}/*`.split("\n")
  s.executables   = []
  s.require_paths = ["lib"]
end
