require 'thor'
require 'git'
require 'os'
require 'json'

class Dit < Thor
  desc "init", "Initialize the current directory as a dit directory."
  def init()
    # Get working dir
    working_dir = Dir.getwd

    # Some checks to see if this is already a .e or git repo
    # You'll be stopped if this is already a .e repo
    if(Dir.exist?(working_dir + "/.dit"))
      p "This is already a dit repo."
      return
    end

    if(Dir.exist?(working_dir + "/.git"))
      repo = Git.open(working_dir)
    else
      repo = Git.init(working_dir)
      puts "Initialized empty Git repository in #{File.join(working_dir, ".git")}"
    end

    # Make a .e dir and a settings hash to be exported to a file in .e dir
    Dir.mkdir(working_dir + "/.dit")
    settings = {}
    
    # create a .gitignore to ignore the os_dotfiles dir
    File.open(File.join(working_dir, ".gitignore"), "a") do |f|
      f.write ".dit/os_dotfiles/"
      f.write "\n"
      f.write ".dit/local_settings.json"
    end

    # Write our changes to a JSON file in the .e dir
    File.open(working_dir + "/.dit" + "/settings.json", "a") do |f|
      f.write settings.to_json if settings
    end

    # commit changes as initial commit
    # (so we can branch)
    repo.add(".dit/settings.json")
    repo.add(".gitignore")
    repo.commit("Dit inital commit")

    clone_os_dotfiles 

    puts "Initialized empty Dit repository in #{File.join(working_dir, ".dit")})"
  end

  desc "clone REPO", "Clone a dit repository."
  def clone(repo)
    repo_name = repo.split("/").pop().split(".")[0]
    repo = Git.clone(repo, repo_name) 
    Dir.chdir(repo_name) do
      clone_os_dotfiles
      symlink_all
    end
  end

  desc "add FILE", "Add a dotfile to the working tree."
  option :all, :type => :boolean, :aliases => '-A'
  def add(f=nil)
    working_dir = Dir.getwd
    repo = Git.open(working_dir)
    options[:all] ? repo.add(:all=>true) : (repo.add(f) if f)
    p "No file specified!" unless (options[:all] || f)
  end

  option :message, :required => true, :aliases => '-m'
  def commit()
    working_dir = Dir.getwd
    repo = Git.open(working_dir)
    repo.commit(options[:message])
    symlink_unlinked
  end

  desc "push", "Push your changes to a dit repository."
  def push()
    working_dir = Dir.getwd
    repo = Git.open(working_dir)
    repo.branches.local.each do |b|
      repo.branch(b).push
    end
  end

  desc "pull", "Pull your changes from a dit repo."
  def pull()
    working_dir = Dir.getwd
    repo = Git.open(working_dir)
    repo.pull
  end

  private

  def clone_os_dotfiles()
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

    if Dir.exist?(".dit") 
      file_url = "file:///" + File.absolute_path(Dir.getwd)
      if os
        Dir.chdir(".dit") do
          os_dotfiles = Git.clone(file_url, "os_dotfiles")
          os_dotfiles.branch(os).checkout
        end
      else
        Dir.chdir(".dit") do
          os_dotfiles = Git.clone(file_url, "os_dotfiles")
          os_dotfiles.branch("master").checkout
        end
      end
    end
  end

  def symlink_all(files)
    Dir.chdir(File.join(repo_name, ".dit", "os_dotfiles")) do
      Find.find('.') do |d|
        if File.directory?(d)
          Dir.mkdir(File.join(Dir.home, d.split['os_dotfiles'][1]))
          Dir.entries(d).each do |f|
            next if (f === '.' || f === '..')
            abs_f = File.absolute_path(f)
            rel_f = File.join(Dir.home, abs_f.split("os_dotfiles")[1])
            File.symlink(abs_f, rel_f) unless File.exists?(rel_f)
          end
        end
      end
    end
  end

  def symlink_unlinked(settings)
    settings = nil
    begin
      settings = JSON.parse File.open(
        File.join(working_dir, ".dit", "local_settings.json"), "r").read.close
    rescue
      settings = {
        symlinked: []
      }
    end

    Dir.chdir(".dit") do
      Dir.chdir("os_dotfiles") do
        Git.open(Dir.getwd).pull
        os_changed_files = `git show --pretty="format:" --name-only HEAD`
        os_changed_files.split('\n').each do |file|
          file.strip! # strip newlines
          p file
          next if os_list.include?(file.split('.').pop())
          next if settings[:symlinked].include?(file) 
          next if file.include?(".dit")
          File.symlink(
            File.absolute_path(file),
            File.absolute_path(File.join(Dir.home, file)))
          settings[:symlinked] << file
        end
      end
    end

    File.open(File.join(working_dir, ".dit", "local_settings.json"), "w+") do |f|
      f.truncate 0
      f.write settings.to_json
    end
  end

end
