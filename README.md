# Dit

Dit is a dotfile manager that hooks into git.

It uses git hooks to automatically run whenever you `git commit` or `git merge`. You just keep working on that dotfiles directory as normal and dit handles the rest.

Windows isn't currently supported due to a conspicious lack of symlinking on windows. Suggestions as to circumvent this restriction are welcome.

## Getting started

Assuming ruby and rubygems are already installed (if not, refer to your various package managers)

`gem install dit`  
`dit init`

Then, use your git repository as normal. Any new files will automatically be symlinked to your home directory.

## OS Specific Dotfiles

**This is a planned feature, and is not present in Dit 0.1**

Dit also knows this little trick:

Given a list of dotfiles

- .dotfile
- .dotfile.arch
- .dotfile.osx

On a Mac OS X computer, your home directory will contain just one dotfile:

- .dotfile

which contains both .dotfile and .dotfile.osx (which is appended to the end of the file.)

It works the same way on your arch linux system, except it contains .dotfile.arch instead of the .osx file.

## Contributing

Please do!

------------------------------

[![forthebadge](http://forthebadge.com/images/badges/built-with-ruby.svg)](http://forthebadge.com)
[![forthebadge](http://forthebadge.com/images/badges/built-with-love.svg)](http://forthebadge.com)
[![forthebadge](http://forthebadge.com/images/badges/uses-badges.svg)](http://forthebadge.com)
