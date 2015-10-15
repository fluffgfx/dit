require 'thor'
require 'git'

class DotE < Thor
  # Fun Fact: .e is a direct descendant of Thor!

  desc "init", "Initialize the current directory as a dotfiles directory."
  def init()
    # Get working dir
    working_dir = Dir.getwd

    # Some checks to see if this is already a .e or git repo
    # You'll be stopped if this is already a .e repo
    if(Dir.exist?(working_dir + "/.e"))
      p "This is already a .e repo."
      return
    end
    if(Dir.exist?(working_dir + "/.git"))
      p "This is already a git repo. It will be converted to a .e repo" +
        " (which is a git repo with sprinkles)"
      git_repo = true
    else
      git_repo = false
    end
    p "If you haven't already created a github repo or whatnot for your" +
      " dotfiles, I'd suggest you do that now!"

    # Get a repo object from ruby-git
    if(git_repo)
      repo = Git.open(working_dir)
      remotes_exist = repo.remotes.length > 0
      many_remotes_exist = repo.remotes.length > 0
    else
      repo = Git.init(working_dir)
    end

    # Make a .e dir and a settings hash to be exported to a file in .e dir
    Dir.mkdir(working_dir + "/.e")
    settings = {}

    # If we've already got remotes, use those, or one of those, or prompt
    if(remotes_exist && many_remotes_exist)
      p "It looks like you have multiple remotes in this repo."
      p "Should I push to every repo you have? (yN)"
      res = gets
      if(res === "y" || res === "Y")
        settings[:push_all_remotes] = true
      else
        settings[:push_all_remotes] = false
        p "OK, then which remote should I push to?"
        p "Your remotes are:"
        repo.remotes.each do |r|
          p r.name
        end
        settings[:remote_name] = gets
        settings[:remote_url] = repo.remote(settings[:remote_name]).url
      end
    elsif(remotes_exist)
      p "We'll push to the #{repo.remotes[0].name} remote."
    else
      p "You should specify a remote to sync your dotfiles to."
      p "Would you like to do that now? (yN)"
      res = gets
      if(res === "y" || res === "Y")
        p "Alright, what's your remote repo URL?"
        settings[:remote_name] = "origin"
        settings[:remote_url] = gets
        repo.add_remote(settings[:remote_name], settings[:remote_url])
      end
    end

    # Write our changes to a JSON file in the .e dir
    File.open(working_dir + "/.e" + "/settings.json") do |f|
      f.write settings.to_json
    end
  end

  desc "clone REPO", "Clone a dotty repository."
  def clone(repo)
    working_dir = Dir.getwd
    # sort of a hacky way to derive repo name
    repo_name = repo.split("/").pop().split(".")[0]
    repo = Git.clone(repo, repo_name) 
    if OS.windows?
      repo.branch('windows').checkout
    elsif OS.x?
      repo.branch('osx').checkout
    elsif OS.linux?
      # detect linux distro
      version = `cat /proc/version`
      if version.include?("Debian")
        repo.branch('debian').checkout
      elsif version.include?("Ubuntu")
        repo.branch('ubuntu').checkout
      elsif version.include?("RHEL")
        repo.branch('redhat').checkout
      elsif version.include?("Arch")
        repo.branch('arch').checkout
      elsif version.include?("SUSE")
        repo.branch('suse').checkout
      elsif version.include?("Fedora")
        repo.branch('fedora').checkout
      end
    # TODO: Prompt for package install
  end

  desc "add FILE", "Add a dotfile to the working tree."
  option :all, :type => :boolean, :aliases => '-A'
  def add(f)
    working_dir = Dir.getwd
    repo = Git.open(working_dir)
    options[:all] ? repo.add(:all=>true) : repo.add(f)
  end

  desc "import FILE", "Import a dotfile to the repository."
  def import(f)
    p "import"
  end

  desc "commit", "Commit your changes to a .e repository."
  option :message, :required => true, :aliases => '-m'
  option :global, :type => :boolean, :aliases => '-g'
  def commit()
    working_dir = Dir.getwd
    repo = Git.open(working_dir)
    repo.commit(options[:message])
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

  # TODO this should be under subcommands
  desc "package add|rm|list [package]", "Modify the .e package system."
  def package(command, package)
    p "package"
  end
end
