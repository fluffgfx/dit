require 'thor'
require 'git'
require 'os'
require 'json'

class Dit < Thor
  desc "init", "Initialize the current directory as a dit directory."
  def init
    if(Dir.exist?(working_dir + "/.dit"))
      p "This is already a dit repo."
      return
    elsif(Dir.exist?(working_dir + "/.git"))
      repo = Git.open(working_dir)
    else
      repo = Git.init(working_dir)
      puts "Initialized empty Git repository in #{File.join(working_dir, ".git")}"
    end

    # Make a .dit dir and a settings hash to be exported to a file in dit dir
    Dir.mkdir(working_dir + "/.dit")
    settings = {}
    
    # create a .gitignore to ignore the os_dotfiles dir
    File.open(File.join(working_dir, ".gitignore"), "a") do |f|
      f.write ".dit/os_dotfiles/"
      f.write "\n"
      f.write ".dit/local_settings.json"
    end

    # Write our changes to a JSON file in the dit dir
    File.open(working_dir + "/.dit" + "/settings.json", "a") do |f|
      f.write settings.to_json if settings
    end

    repo.add(".dit/settings.json")
    repo.add(".gitignore")
    repo.commit("Dit inital commit")

    clone_os_dotfiles
    puts "Initialized empty Dit repository in #{File.join(working_dir, ".dit")})"
  end

  desc "clone REPO", "Clone a dit repository."
  def clone(repo)
    repo_name = repo.split("/").pop().split(".")[0]
    Git.clone(repo, repo_name) 
    Dir.chdir(repo_name) do
      clone_os_dotfiles
      symlink_all
    end
  end

  option :message, :required => true, :aliases => '-m'
  def commit
    repo.commit(options[:message])
    symlink_unlinked
  end

  desc "pull", "Pull your changes from a dit repo."
  def pull
    repo.pull
    symlink_unlinked # In case there were changed files
  end
  
  desc "rehash", "In case you ran a git command when you should've run a dit command."
  def rehash
    symlink_unlinked
  end

  private

  def clone_os_dotfiles
    # OS Specific Dotfiles Eventually TM
    file_url = "file:///" + File.absolute_path(Dir.getwd)
    Dir.chdir(".dit") do
      os_dotfiles = Git.clone(file_url, "os_dotfiles")
      os_dotfiles.branch("master").checkout
    end
  end

  def symlink_all
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

  def symlink_unlinked
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
  
  def working_dir
    Dir.getwd
  end
  
  def repo
    Git.open(working_dir)
  end
end
