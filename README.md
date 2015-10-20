# Dit

Dit is a dotfile manager that thinks it's git.

It uses ruby-git and just under 200 lines of code to automatically handle all your dotfiles for you. You can execute basic git commands just as it were a git repo, except dit will also automatically symlink everything to your home dir when you commit, or when you clone an existing dit repo. It's like magic.

Windows isn't currently supported due to a conspicious lack of symlinking on windows. Suggestions as to circumvent this restriction are welcome.

## How does it work?

Dit uses all the git commands you're used to.

### Getting started

Assuming ruby and rubygems are already installed (if not, refer to your various package managers)

`gem install dit`  
`dit init`

### Importing an existing dotfiles repo

`dit clone [git url]`

### Committing your changes

`dit commit -m "Commit Message"`

### Get the most recent changes

`dit pull`

### There's a file that isn't symlinked to my home dir

`dit rehash`

### What about [some git command]?

`git [some git command]`

The beauty of dit is that all it does is layer itself very softly upon git, so anything dit doesn't handle directly doesn't have to be handled by dit - because that's what git is for.

## Contributing

Please do!

------------------------------

[![forthebadge](http://forthebadge.com/images/badges/built-with-ruby.svg)](http://forthebadge.com)
[![forthebadge](http://forthebadge.com/images/badges/built-with-love.svg)](http://forthebadge.com)
[![forthebadge](http://forthebadge.com/images/badges/uses-badges.svg)](http://forthebadge.com)
