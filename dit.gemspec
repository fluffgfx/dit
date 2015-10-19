Gem::Specification.new do |s|
  s.name = "Dit"
  s.version = "0.1"
  s.date = "2015-10-14"
  s.summary = "Dit is a dotfiles manager that thinks it's git."
  s.description = "Dit is a dotfiles manager that wraps around git and makes " +
    "dotfiles easy to manage across devices."
  s.authors = [ "Kyle Fahringer" ]
  s.files = [ "lib/dit.rb" ]
  s.executables << 'dit'
  s.license = "MIT"
  s.homepage = "http://github.com/vulpino/dit"
  s.add_runtime_dependency 'thor'
  s.add_runtime_dependency 'git'
  s.add_runtime_dependency 'os'
end
