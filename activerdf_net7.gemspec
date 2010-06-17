require 'fileutils'
include FileUtils

Gem::Specification.new do |s|
  s.name = 'activerdf_net7'
  s.summary = 'Offers object-oriented access to RDF (with adapters to several datastores). Version of the Talia project.'
  s.description = s.summary + ' THIS IS NOT THE OFFICIAL VERSION.'
  s.authors = ['Eyal Oren', 'The Talia Team']
  s.email = 'hahn@netseven.it'
  s.homepage = 'http://www.activerdf.org'
  s.autorequire = 'active_rdf'
  s.files = Dir.glob("lib/**/*") +
    ['Rakefile', 'activerdf_net7.gemspec','lib/active_rdf.rb',
     'README.rdoc','CHANGELOG','LICENSE']
  s.extra_rdoc_files = ["README.rdoc", "CHANGELOG", "LICENSE"]
  s.add_dependency('grit', '>= 1.1.1')
  s.version = "1.7.0"
  s.date = "2010-05-11"
  s.require_path = "lib/"
  s.has_rdoc = true
end

