require 'fileutils'

module FileUtils
  class << self
    alias_method :old_mkdir_p, :mkdir_p
    def mkdir_p list, options = {}
      begin
        old_mkdir_p list, options
      rescue Errno::EACCES => e
        STARMAN::CLI.report_error "Failed to create directory #{STARMAN::CLI.red list}! Create it manually by using sudo, then back."
      end
    end

    alias_method :old_mkdir, :mkdir
    def mkdir list, options = {}
      begin
        rm_rf list, :secure => true if options[:force]
        options.delete :force
        old_mkdir list, options
      rescue Errno::EACCES => e
        STARMAN::CLI.report_error "Failed to create directory #{STARMAN::CLI.red list}! Create it manually by using sudo, then back."
      end
    end

    def write file_path, content
      dir = File.dirname file_path
      mkdir_p dir if not Dir.exist? dir
      file = File.new file_path, 'w'
      file << content
      file.close
    end
  end
end