require 'thor'
require 'git'

class DotE < Thor
  # Fun Fact: .e is a direct descendant of Thor!

  desc "init", "Initialize the current directory as a dotfiles directory."
  def init()
    p "Ay!"
  end

  desc "clone REPO", "Clone a dotty repository."
  def clone(repo)
    p "clone"
  end

  desc "add FILE", "Add a dotfile to the working tree."
  def add(f)
    p "add"
  end

  desc "import FILE", "Import a dotfile to the repository."
  def import(f)
    p "import"
  end

  desc "commit", "Commit your changes to a .e repository."
  def commit()
    p "commit"
  end

  desc "push", "Push your changes to a .e repository."
  def push()
    p "push"
  end

  desc "pull", "Pull your changes from a .e repo."
  def pull()
    p "pull"
  end

  desc "branch OS", "Branch your repo to make OS specific changes."
  def branch(os)
    p "branch"
  end

  desc "os OS", "Set your current OS when it isn't auto detected."
  def os(os)
    p "os"
  end

  desc "package add|rm|list [package]", "Modify the .e package system."
  def package(command, package)
    p "package"
  end
end
