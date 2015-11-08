# Dit

![Dit version](https://img.shields.io/gem/v/dit.svg)

Dit is a dotfile manager that hooks into git.

It uses git hooks to automatically run whenever you `git commit` or `git merge`. You just keep working on that dotfiles directory as normal and dit handles the rest.

Windows isn't currently supported due to a conspicious lack of symlinking on windows. Suggestions as to circumvent this restriction are welcome.

## Getting started

Assuming ruby and rubygems are already installed (if not, refer to your various package managers)

`gem install dit`  
`cd ~/my_dotfiles`  
`dit init`

Then, use your git repository as normal. Any new files will automatically be symlinked to your home directory.

## Contributing

Please do!

------------------------------

[![forthebadge](http://forthebadge.com/images/badges/built-with-ruby.svg)](http://forthebadge.com)
[![forthebadge](http://forthebadge.com/images/badges/built-with-love.svg)](http://forthebadge.com)
[![forthebadge](http://forthebadge.com/images/badges/uses-badges.svg)](http://forthebadge.com)
