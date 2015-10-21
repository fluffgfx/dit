require 'thor'
require 'git'
require 'os'
require 'json'
require 'fileutils'
require 'find'

class Dit
  def self.init
    unless Dir.exist?(".git")
      Git.init(Dir.getwd)
      puts "Initialized empty Git repository in #{File.join(Dir.getwd, ".git")}"
    end

    # KISS - Just handle symlinking and git hooks
    symlink_all
    hook
    puts "Hooked in dit"
  end

  def self.hook
    Dir.chdir(File.join(".git", "hooks")) do
      # The following check for the existence of post-commit or post-merge hooks
      # and will not interfere with them if they exist and do not use bash.
      post_commit_hook_exists = File.exist?("post-commit")
      post_merge_hook_exists = File.exist?("post-merge")
      append_to_post_commit, append_to_post_merge, cannot_post_commit, 
        cannot_post_merge = nil

      if(post_commit_hook_exists || post_merge_hook_exists)
        if post_commit_hook_exists
          if `cat post-commit`.include?("#!/usr/bin/env bash")
            puts "You have post-commit hooks already that use bash, so we'll " +
              "append ourselves to the file."
            append_to_post_commit = true
          else
            puts "You have post-commit hooks that use some foreign language, " +
              "so we won't interfere, but we can't hook in there."
            cannot_post_commit = true
          end
        end

        if post_merge_hook_exists
          if `cat post-merge`.include?("#!/usr/bin/env bash")
            puts "You have post-merge hooks already that use bash, so we'll " +
              "append ourselve to the file."
            append_to_post_merge = true
          else
            puts "You have post-merge hooks that use some not-bash language, " +
              "so we won't interfere, but we can't hook in there."
            cannot_post_merge = true
          end
        end
      end

      unless cannot_post_commit
        File.open("post-commit", "a") do |f|
          f.write "#!/usr/bin/env bash\n" unless append_to_post_commit
          f.write "( exec ./.git/hooks/dit )\n"
        end
      end

      unless cannot_post_merge
        File.open("post-merge", "a") do |f|
          f.write "#!/usr/bin/env bash\n" unless append_to_post_merge
          f.write "( exec ./.git/hooks/dit )\n"
        end
      end

      # Both scripts call a dit helper script instead of including the code
      # directly.
      File.open("dit", "a") do |f|
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
        File.open("force-ruby", "a") do |f|
          f.write "#!/usr/bin/env bash\n"
          f.write "set -e\n"
          if ENV['RBENV_ROOT']
            # Use Rbenv's shims instead of directly going to ruby bin
            # By the way, if anyone has particular PATHs I should use for
            # RVM or chruby, please let me know!
            f.write "PATH=#{File.join(ENV['RBENV_ROOT'], "shims")}:$PATH\n"
          else
            f.write "PATH=#{ruby_folder}:$PATH\n"
          end
          f.write "exec ruby \"$@\"\n"
        end
      else
        File.open("force-ruby", "a") do |f|
          f.write "#!/usr/bin/env bash\n"
          f.write "exec ruby \"$@\"\n"
        end
      end
      # Make sure they're executable
      FileUtils.chmod '+x', %w(post-commit post-merge dit force-ruby)
    end
  end

  def self.symlink_all
    errors = 0
    Find.find('.') do |d|
      if File.directory?(d)
        next if d === '.'
        puts d
        next if d.include?(".git")
        begin
          Dir.mkdir(File.join(Dir.home, d.gsub(Dir.getwd, '')))
        rescue
          puts "Failed to create directory #{d}"
        end
        Dir.entries(d).each do |f|
          next if (f === '.' || f === '..' || File.directory?(f))
          abs_f = File.absolute_path(f)
          rel_f = File.join(Dir.home, abs_f.gsub(Dir.getwd, ''))
          errors += symlink(abs_f, rel_f)
        end
      end
    end
    puts "Failed to symlink #{errors.to_s} files." if errors > 0
  end

  def self.symlink_unlinked
    changed_files = `git show --pretty="format:" --name-only HEAD`.split("\n")
    puts changed_files
    errors = 0
    Find.find('.') do |d|
      puts d
      if File.directory?(d)
        home_d = File.join Dir.home, File.absolute_path(d).gsub(Dir.getwd, '')
        Dir.mkdir(home_d) unless (File.directory?(home_d) || d === '.')
        Dir.entries(d) do |f|
          next if (f === '.' || f === '..' || File.directory?(f))
          abs_f = File.absolute_path f
          rel_f = abs_f.gsub(Dir.getwd, '')
          puts rel_f
          next unless changed_files.include?(rel_f)
          home_f = File.join Dir.home, rel_f
          errors += symlink(abs_f, home_f)
        end
      end
    end
    puts "Failed to symlink #{errors.to_s} files." if errors > 0
  end

  private

  def self.repo
    Git.open(Dir.getwd)
  end

  def self.symlink(abs_f, rel_f)
    begin
      File.symlink(abs_f, rel_f)
      puts "Failed to symlink #{abs_f} to #{rel_f}"
      return 0
    rescue
      return 1
    end
  end

end

class DitCMD < Thor
  desc "init", "Initialize the current directory as a dit directory."
  def init
    Dit.init
  end

  desc "rehash", "Manually symlink everything in case a git hook didn't run."
  def rehash
    Dit.symlink_all
  end
end
