# encoding: UTF-8

$:.push( File.expand_path( "../lib", __FILE__ ) )

require "spreadbase/version"

Gem::Specification.new do |s|
  s.name        = "spreadbase"
  s.version     = SpreadBase::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = [ "Saverio Miroddi" ]
  s.email       = [ "saverio.pub2@gmail.com" ]
  s.homepage    = ""
  s.summary     = %q{Library for reading/writing OpenOffice Calc documents.}
  s.description = %q{In addition to the summary, it also prepare the coffee. Many times a day!!}

  s.add_runtime_dependency     "zipruby", "~>0.3.6"
  s.add_development_dependency "rspec",   "~>2.9.0"

  s.files         = `git ls-files`.split( "\n" )
  s.test_files    = `git ls-files -- {spec,temp,utils}/*`.split( "\n" )
  s.executables   = []
  s.require_paths = [ "lib" ]
end
