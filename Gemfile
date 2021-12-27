source 'https://rubygems.org'

gemspec

if Gem.ruby_version >= Gem::Version.new('3.0.0')
  gem 'rexml'
end

if ENV['USE_RUBYZIP_3'] == 'yes'
  if gemspec_cache = Bundler.instance_variable_get(:@gemspec_cache)
    gemspec_cache
      .values
      .find { |s| s.name == 'spreadbase' }
      .dependencies.delete_if { |d| d.name == 'rubyzip' }
  end
  gem 'rubyzip', github: 'rubyzip/rubyzip'
end
