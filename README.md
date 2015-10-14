# .e

.e (Dot E) is a dotfiles manager that thinks it's git.

## Getting started

Move into an empty directory where you want to store your dotfiles.

`dot_e init`

.e will walk you through the process of setting up a dotfiles directory.

## Importing an existing dotfiles repo

`dot_e clone [git url]`

## Importing an existing dotfile on the system

`dot_e import [url of dotfile relative to ~]`

e.g.

`dot_e import .vimrc`

imports ~/.vimrc

If you want to import a file relative to root, just prefix the file with /.

`dot_e import /home/ThisIsAUsername/.vimrc`

## Committing your changes

`dot_e commit`

## Push your changes to your git repository

`dot_e push`

## Get the most recent changes

`dot_e pull`

## OS Specific dotfiles

`dot_e branch [os]`

e.g.

`dot_e branch os_x`

The following will autodetect:

- os\_x (or osx, or macos)
- windows (or win, or i\_wish\_i\_had\_my\_programming\_system\_right\_now)
- arch
- debian
- ubuntu
- fedora

If you're not listed, .e will assume not load any OS specific files until you run

`dot_e os [os]`

where OS is the same name as the branch you used.

## Packages

`dot_e package add [package]`
`dot_e package rm [package]`
`dot_e package list`

.e will prompt every time a .e repo is cloned to install the packages listed. It will then install them using the local package manager.

Note that OSX requires homebrew to be installed, and windows requires Chocolatey.
