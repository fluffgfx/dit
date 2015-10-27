require 'thor'
require 'git'
require 'os'
require 'json'
require 'fileutils'

class Dit
  # This is the class where all the dit work is done.
  # The thor class is basically a very thin layer on top of this that just
  # calls its methods directly.
  def self.init
    if OS.windows?
      puts 'This is a windows system, and dit does not support windows.'
      puts 'See vulpino/dit issue #1 if you have a potential solution.'
      return
    end

    if Dir.exist?('.git')
      puts 'Dit has detected an existing git repo, and will initialize it to ' +
        'populate your ~ directory with symlinks.'
      puts 'Please confirm this by typing y, or anything else to cancel.'
      response = STDIN.gets.chomp.upcase
      return unless (response == 'Y')
      symlink_all
    else
      Git.init(Dir.getwd)
      puts "Initialized empty Git repository in #{File.join(Dir.getwd, '.git')}"
    end
    hook
    puts 'Dit was successfully hooked into .git/hooks.'
  end

  def self.hook
    Dir.chdir(File.join('.git', 'hooks')) do
      # The following check for the existence of post-commit or post-merge hooks
      # and will not interfere with them if they exist and do not use bash.
      append_to_post_commit, cannot_post_commit = hook 'post-commit'
      append_to_post_merge, cannot_post_merge = hook 'post-merge'

      add_hook('post-commit', append_to_post_commit) unless cannot_post_commit
      add_hook('post-merge', append_to_post_merge) unless cannot_post_merge

      make_dit
      make_ruby_enforcer

      # Make sure they're executable
      FileUtils.chmod '+x', %w(post-commit post-merge dit force-ruby)
    end
  end

  def self.symlink_list(list)
    list.each do |f|
      f.strip!
      wd_f = File.absolute_path f
      home_f = File.absolute_path(f).gsub(Dir.getwd, Dir.home)
      symlink wd_f, home_f
    end
  end

  def self.symlink_unlinked
    symlink_list `git show --pretty="format:" --name-only HEAD`.split("\n")
  end

  def self.symlink_all
    current_branch = `git rev-parse --abbrev-ref HEAD`.chomp
    symlink_list `git ls-tree -r #{current_branch} --name-only`.split("\n")
  end

  def self.repo
    Git.open(Dir.getwd)
  end

  def self.symlink(a, b)
    File.symlink(a, b)
  rescue
    puts "Failed to symlink #{a} to #{b}"
  end

  def self.detect_existing_hook(hook)
    hook_exists = File.exist?(hook)

    cannot_hook, append_to_hook = false

    if hook_exists
      if `cat #{hook}`.include?('./.git/hooks/dit')
        puts 'Dit hook already installed.'
        cannot_hook = true
      elsif `cat #{hook}`.include?('#!/usr/bin/env bash')
        puts "You have #{hook} hooks already that use bash, so we'll " +
          'append ourselves to the file.'
        append_to_hook = true
      else
        puts "You have #{hook} hooks that use some foreign language, " +
          "so we won't interfere, but we can't hook in there."
        cannot_hook = true
      end
    end

    [append_to_hook, cannot_hook]
  end

  def self.write_hook(hook_file, do_append)
    File.open(hook_file, 'a') do |f|
      f.write "#!/usr/bin/env bash\n" unless do_append
      f.write "( exec ./.git/hooks/dit )\n"
    end
  end

  def self.make_dit
    File.open('dit', 'a') do |f|
      f.write "#!/usr/bin/env ./.git/hooks/force-ruby\n"
      f.write "require 'dit'\n"
      f.write "Dit.symlink_unlinked\n"
    end
  end

  def self.make_ruby_enforcer
    # The following lines are because git hooks do this weird thing
    # where they prepend /usr/bin to the path and a bunch of other stuff
    # meaning git hooks will use /usr/bin/ruby instead of any ruby
    # from rbenv or rvm or chruby, so we make a script forcing the hook
    # to use our ruby
    ruby_path = `which ruby`
    if ruby_path != '/usr/bin/ruby'
      ruby_folder = File.dirname(ruby_path)
      File.open('force-ruby', 'a') do |f|
        f.write "#!/usr/bin/env bash\n"
        f.write "set -e\n"
        if ENV['RBENV_ROOT']
          # Use Rbenv's shims instead of directly going to ruby bin
          # By the way, if anyone has particular PATHs I should use for
          # RVM or chruby, please let me know!
          f.write "PATH=#{File.join(ENV['RBENV_ROOT'], 'shims')}:$PATH\n"
        else
          f.write "PATH=#{ruby_folder}:$PATH\n"
        end
        f.write "exec ruby \"$@\"\n"
      end
    else
      File.open('force-ruby', 'a') do |f|
        f.write "#!/usr/bin/env bash\n"
        f.write "exec ruby \"$@\"\n"
      end
    end
  end
end

class DitCMD < Thor
  desc 'init', 'Initialize the current directory as a dit directory.'
  def init
    Dit.init
  end

  desc 'rehash', "Manually symlink everything in case a git hook didn't run."
  def rehash
    Dit.symlink_all
  end
end
