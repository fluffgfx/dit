# Dit

Dit is a dotfile manager that thinks it's git.

It uses ruby-git and just under 200 lines of code to automatically handle all your dotfiles for you. You can execute basic git commands just as it were a git repo, except dit will also automatically symlink everything to your home dir when you commit, or when you clone an existing dit repo. It's like magic.

## Getting started

`gem install dit` 
`dit init`

## Importing an existing dotfiles repo

`dit clone [git url]`

## Committing your changes

`dit commit -m "Commit Message"`

## Push your changes to your git repository

`dit push`

## Get the most recent changes

`dit pull`

