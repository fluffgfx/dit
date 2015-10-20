require 'thor'
require 'git'
require 'os'
require 'json'
require 'fileutils'

class Dit
  def self.init
    if(Dir.exist?(".dit"))
      puts "This is already a dit repo, so all we have to do is symlink to home."
      symlink_all
      hook
      return
    elsif(Dir.exist?(".git"))
      repo = Git.open(Dir.getwd)
    else
      repo = Git.init(Dir.getwd)
      puts "Initialized empty Git repository in #{File.join(Dir.getwd, ".git")}"
    end

    # Make a .dit dir and a settings hash to be exported to a file in dit dir
    Dir.mkdir(".dit")
    settings = {}
    
    # create a .gitignore to ignore the os_dotfiles dir
    File.open(".gitignore", "a") do |f|
      f.write ".dit/os_dotfiles/"
      f.write "\n"
      f.write ".dit/local_settings.json"
    end

    # Write our changes to a JSON file in the dit dir
    File.open(File.join(".dit", "settings.json"), "a") do |f|
      f.write settings.to_json if settings
    end

    repo.add(".dit/settings.json")
    repo.add(".gitignore")
    repo.commit("Dit inital commit")

    clone_os_dotfiles
    hook

    puts "Initialized empty Dit repository in #{File.join(Dir.getwd, ".dit")})"
  end

  def self.hook
    return unless Dir.exist?(".dit")
    Dir.chdir(File.join(".git", "hooks")) do
      p Dir.getwd
      FileUtils.rm_rf Dir.glob("*")
      File.open(("post-commit"), "a") do |f|
        f.write "#!/usr/bin/env ./.git/hooks/force-ruby\n"
        f.write "require 'dit'\n"
        f.write "Dit.symlink_unlinked\n"
      end
      File.open(("post-merge"), "a") do |f|
        f.write "#!/usr/bin/env ./.git/hooks/force-ruby\n"
        f.write "require 'dit'\n"
        f.write "Dit.symlink_unlinked\n"
      end
      # The following lines are because git hooks do this weird thing
      # where they prepend /usr/bin to the path and a bunch of other stuff
      # meaning git hooks will use /usr/bin/ruby instead of any ruby
      # from rbenv or rvm or chruby, so we make a script forcing the hook
      # to use our ruby
      ruby_path = `which ruby`
      if(ruby_path != "/usr/bin/ruby")
        ruby_folder = File.dirname(ruby_path)
        File.open(("force-ruby"), "a") do |f|
          f.write "#!/usr/bin/env bash\n"
          f.write "set -e\n"
          if ENV['RBENV_ROOT']
            # Use Rbenv's shims
            # By the way, if anyone has particular PATHs I should use for
            # RVM or chruby, please let me know!
            f.write "PATH=#{File.join(ENV['RBENV_ROOT'], "shims")}:$PATH\n"
          else
            f.write "PATH=#{ruby_folder}:$PATH\n"
          end
          f.write "exec ruby \"$@\"\n"
        end
      end
        
      FileUtils.chmod '+x', %w(post-commit post-merge force-ruby)
    end
  end

  def self.clone_os_dotfiles
    # OS Specific Dotfiles Eventually TM
    file_url = "file:///" + File.absolute_path(Dir.getwd)
    Dir.chdir(".dit") do
      os_dotfiles = Git.clone(file_url, "os_dotfiles")
      os_dotfiles.branch("master").checkout
    end
  end

  def self.symlink_all
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

  def self.symlink_unlinked
    settings = nil
    begin
      settings = JSON.parse File.open(
                  File.join(Dir.getwd, ".dit", "local_settings.json"), "r").read.close
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

    File.open(File.join(Dir.getwd, ".dit", "local_settings.json"), "w+") do |f|
      f.truncate 0
      f.write settings.to_json
    end
  end

  private

  def self.repo
    Git.open(Dir.getwd)
  end

  def self.os_list
    [
      'windows',
      'osx',
      'arch',
      'fedora',
      'debian',
      'ubuntu',
      'slack',
      'bsd'
    ]
  end
end

class DitCMD < Thor
  desc "init", "Initialize the current directory as a dit directory."
  def init
    Dit.init
  end
end
