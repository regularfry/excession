lib = File.expand_path("../lib", __FILE__)
$:.unshift(lib) unless $:.include?(lib)

require 'excession/version'

Gem::Specification.new do |s|
  s.name = "excession"
  s.version = Excession::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["Alex Young"]
  s.email = ["alex@blackkettle.org"]
  s.homepage = "http://github.com/regularfry/excession"
  s.summary = "Useful code for handling CSS files"
  s.description = <<-DESCRIPTION
Excession is a collection of code for parsing and otherwise
munging CSS files. It has sprung from a need to be able to
programmatically modify colours in a site's style sheets.
DESCRIPTION

  s.required_rubygems_version = ">= 1.3.6"
  
  s.files = Dir["lib/**/*.rb"]
  s.require_path = "lib"
end
