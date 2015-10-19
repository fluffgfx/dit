require 'thor'
require 'git'
require 'os'
require 'json'

class Dit < Thor
  desc "init", "Initialize the current directory as a dotfiles directory."
  def init()
    # Get working dir
    working_dir = Dir.getwd

    # Some checks to see if this is already a .e or git repo
    # You'll be stopped if this is already a .e repo
    if(Dir.exist?(working_dir + "/.dit"))
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
    Dir.mkdir(working_dir + "/.dit")
    settings = {}

    # If we've already got remotes, use those, or one of those, or prompt
    if(remotes_exist && many_remotes_exist)
      p "It looks like you have multiple remotes in this repo."
      p "Should I push to every repo you have? (yN)"
      res = STDIN.gets
      if(res === "y" || res === "Y")
        settings[:push_all_remotes] = true
      else
        settings[:push_all_remotes] = false
        p "OK, then which remote should I push to?"
        p "Your remotes are:"
        repo.remotes.each do |r|
          p r.name
        end
        settings[:remote_name] = STDIN.gets
        settings[:remote_url] = repo.remote(settings[:remote_name]).url
      end
    elsif(remotes_exist)
      p "We'll push to the #{repo.remotes[0].name} remote."
    else
      p "You should specify a remote to sync your dotfiles to."
      p "Would you like to do that now? (yN)"
      res = STDIN.gets.chomp
      p res
      if(res === "y" || res === "Y")
        p "Alright, what's your remote repo URL?"
        settings[:remote_name] = "origin"
        settings[:remote_url] = STDIN.gets
        repo.add_remote(settings[:remote_name], settings[:remote_url])
      end
    end
    
    # create a .gitignore to ignore the os_dotfiles dir
    File.open(File.join(working_dir, ".gitignore"), "a") do |f|
      f.write ".dit/os_dotfiles/"
    end

    # Write our changes to a JSON file in the .e dir
    File.open(working_dir + "/.dit" + "/settings.json", "a") do |f|
      f.write settings.to_json
    end
  end

  desc "clone REPO", "Clone a dotty repository."
  def clone(repo)
    # sort of a hacky way to derive repo name
    repo_name = repo.split("/").pop().split(".")[0]
    repo = Git.clone(repo, repo_name) 

    # get os
    os = nil
    if OS.windows?
      os = 'windows'
    elsif OS.x?
      os = 'osx'
    elsif OS.linux?
      # cat to the rescue
      distro = `cat /etc/*-release`
      if distro.include?("Arch Linux")
        os = "arch"
      elsif distro.include?("debian")
        os = "debian"
      elsif distro.include?("gentoo")
        os = "gentoo"
      elsif distro.include?("redhat")
        os = "redhat"
      elsif distro.include?("SuSE")
        os = "suse"
      end
    end

    # clone os_dotfiles
    Dir.chdir(repo_name) do
      if Dir.exist?(".dit") 
        if os
          Dir.chdir(".dit") do
            os_dotfiles = Git.clone(repo, "os_dotfiles")
            os_dotfiles.branch(os).checkout
          end
        else
          Dir.chdir(".dit") do
            os_dotfiles = Git.clone(repo, "os_dotfiles")
            os_dotfiles.branch("master").checkout
          end
        end
      end
    end

    # symlink files to ~
    Dir.chdir(File.join(repo_name, ".dit", "os_dotfiles")) do
      Find.find('.') do |d|
        if File.directory?(d)
          Dir.mkdir(File.join(Dir.home, d.split['os_dotfiles'][1]))
          Dir.entries(d).each do |f|
            next if (f === '.' || f === '..')
            abs_f = File.absolute_path(f)
            rel_f = File.join(Dir.home, abs_f.split("os_dotfiles")[1])
            begin
              File.symlink(abs_f, rel_f)
            rescue
              p "This system doesn't support symlinking, sorry"
              # TODO: this will spam every time it tries to symlink huh
            end
          end
        end
      end
    end
    # TODO: Prompt for package install
  end

  desc "add FILE", "Add a dotfile to the working tree."
  option :all, :type => :boolean, :aliases => '-A'
  def add(f=nil)
    working_dir = Dir.getwd
    repo = Git.open(working_dir)
    options[:all] ? repo.add(:all=>true) : (repo.add(f) if f)
    p "No file specified!" unless (options[:all] || f)
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
    
    # Now, process OS specific files and commit to OS branches
    os_list = [
      'windows',
      'osx',
      'linux',
      'arch',
      'debian',
      'ubuntu',
      'redhat',
      'fedora'
    ]
    changed_files = `git show --pretty="format:" --name-only HEAD`
    os_list.each do |os|
      changed_files.split('\n').each do |file|
        if file.split('.').pop() === os
          file_content = nil
          File.open(file, "r") do |f|
            file_content = f.read
          end
          file_normal = file.gsub("." + os, "")
          repo.branch(os).checkout
          File.open(file_normal, "a").write('\n').write(file_content).close
          repo.add(file_normal)
          repo.commit("Autogenerated .e commit - update #{file_normal}")
          repo.branch('master').checkout
        end
      end
    end
    # TODO: Symlinking new files
  end

  desc "push", "Push your changes to a .e repository."
  def push()
    working_dir = Dir.getwd
    repo = Git.open(working_dir)
    repo.branches.local.each do |b|
      repo.branch(b).push
    end
  end

  desc "pull", "Pull your changes from a .e repo."
  def pull()
    working_dir = Dir.getwd
    repo = Git.open(working_dir)
    repo.pull
  end

  desc "os OS", "Set your current OS when it isn't auto detected."
  def os(os)
    working_dir = Dir.getwd
    os_dotfiles = Git.open(File.join(working_dir, ".dit", "os_dotfiles"))
    os_dotfiles.branch(os).checkout

    # symlink files to ~
    # TODO: this can probably be a method
    Dir.chdir(File.join(repo_name, ".dit", "os_dotfiles")) do
      Find.find('.') do |d|
        if File.directory?(d)
          Dir.mkdir(File.join(Dir.home, d.split['os_dotfiles'][1]))
          Dir.entries(d).each do |f|
            next if (f === '.' || f === '..')
            abs_f = File.absolute_path(f)
            rel_f = Dir.home + 
              File.SEPARATOR  + 
              abs_f.split("os_dotfiles")[1]
            begin
              File.symlink(abs_f, rel_f)
            rescue
              p "This system doesn't support symlinking, sorry"
            end
          end
        end
      end
    end
  end

  # TODO this should be under subcommands
  desc "package add|rm|list [package]", "Modify the .e package system."
  def package(command, package)
    p "package"
  end
end
