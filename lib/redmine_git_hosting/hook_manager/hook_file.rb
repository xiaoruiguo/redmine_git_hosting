require 'digest/md5'

module RedmineGitHosting::HookManager

  class HookFile

    attr_reader :name
    attr_reader :source_path
    attr_reader :destination_path
    attr_reader :filemode


    def initialize(name, source_path, destination_path, executable)
      @name             = name
      @source_path      = source_path
      @destination_path = destination_path
      @filemode         = executable ? '755' : '644'
      @force_update     = RedmineGitHosting::Config.gitolite_force_hooks_update?
    end


    def installed?
      if !exists?
        logger.info("Hook '#{name}' does not exist, installing it ...")
        do_install_file
      elsif hook_are_different?
        logger.warn("Hook '#{name}' is already present but it's not ours!")

        if @force_update
          logger.info("Restoring '#{name}' hook since forceInstallHook == true")
          do_install_file
        end
      end
      return exists?
    end


    private


      def do_install_file
        if install_hook_file
          logger.info("Hook '#{name}' installed")
          update_gitolite
        end
      end


      def logger
        RedmineGitHosting.logger
      end


      def hook_are_different?
        local_md5 != distant_md5
      end


      def local_md5
        Digest::MD5.hexdigest(File.read(source_path))
      end


      def distant_md5
        content = RedmineGitHosting::Commands.sudo_capture('eval', 'cat', destination_path) rescue ''
        Digest::MD5.hexdigest(content)
      end


      def exists?
        begin
          RedmineGitHosting::Commands.sudo_file_exists?(destination_path)
        rescue RedmineGitHosting::Error::GitoliteCommandException => e
          return false
        end
      end


      def install_hook_file
        logger.info("Installing hook '#{source_path}' in '#{destination_path}'")
        RedmineGitHosting::Commands.sudo_install_file(File.read(source_path), destination_path, filemode)
      end


      def update_gitolite
        RedmineGitHosting::Commands.sudo_update_gitolite!
      end

  end
end
