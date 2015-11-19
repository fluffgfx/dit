require 'date'

Gem::Specification.new do |s|
  s.name = 'dit'
  s.version = '0.4'
  s.date = Date.today.strftime('%Y-%m-%d')
  s.summary = "Dit is a dotfiles manager that thinks it's git."
  s.description = 'Dit is a dotfiles manager that wraps around git and makes ' \
    'dotfiles easy to manage across devices.'
  s.authors = ['Kyle Fahringer']
  s.files = ['lib/dit.rb']
  s.executables << 'dit'
  s.license = 'MIT'
  s.homepage = 'http://github.com/vulpino/dit'
  s.email = 'hispanic@hush.ai'
  s.add_runtime_dependency 'thor', '~> 0.19.1'
  s.add_runtime_dependency 'git', '~> 1.2', '>= 1.2.9'
  s.add_runtime_dependency 'os', '~> 0.9.6'
end
