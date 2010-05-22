Gem::Specification.new do |s|
  s.name = "activerdf-sparql"
  s.version = "1.3.6"
  s.date = "2010-05-11"
  s.require_path = "lib/"
  s.has_rdoc = true
  s.files = ["Rakefile", "activerdf-sparql.gemspec", 'lib/activerdf_sparql'] + 
  Dir.glob("lib/**/*")
  s.summary = "ActiveRDF adapter to SPARQL endpoint" 
  s.description = s.summary
  s.author="Eyal Oren <eyal.oren@deri.org"
  s.add_dependency('gem_plugin', '>= 0.2.1')
  s.add_dependency('activerdf', '>= 1.6.4')
  s.add_dependency('json', '>= 1.1.1')
end
