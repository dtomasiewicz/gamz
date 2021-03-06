Gem::Specification.new do |s|
  s.name        = 'gamz'
  s.version     = '0.0.0'
  s.summary     = 'Client-server game framework.'
  s.description = 'Gamz is a framework to allow quick construction of client-server games with a Ruby server component.'

  s.author   = 'Daniel Tomasiewicz'
  s.email    = 'dtomasiewicz@gmail.com'
  s.homepage = 'http://github.com/dtomasiewicz/gamz'
  s.license = 'MIT'

  s.required_ruby_version = '>= 1.9.2'
  s.files    = Dir['README.markdown', 'MIT-LICENSE', 'lib/**/*', 'examples/**/*']
end
