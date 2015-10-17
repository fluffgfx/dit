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

Name your file like this:

`.vimrc.windows`

It'll be appended to .vimrc, but only on windows systems.

We also support:

- Windows (.windows)
- Mac OS X (.osx)
- Arch Linux (.arch)
- Debian (.debian)
- Ubuntu (.ubuntu)
- Redhat (.redhat)
- Fedora (.fedora)

## Packages

`dot_e package add [package]`
`dot_e package rm [package]`
`dot_e package list`

.e will prompt every time a .e repo is cloned to install the packages listed. It will then install them using the local package manager.

Note that OSX requires homebrew to be installed, and windows requires Chocolatey.
