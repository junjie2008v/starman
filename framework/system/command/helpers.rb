module STARMAN
  module System
    module Command
      def system_command? cmd
        `which #{cmd} 2>&1`
        $?.success?
      end

      def full_command_path cmd
        `which #{cmd}`.chomp
      end

      def run cmd, *options
        CompilerStore.set_default_flags
        args = options.select { |option| option.class == String }
        if cmd == 'make' and not options.include? :single_job
          options << "-j#{CommandLine.options[:'make-jobs'].value}"
        end
        options.delete(:single_job)
        sources = ''
        System::Shell.source_files.each do |file|
          sources << "source #{file} && "
        end
        cmd_str = "#{cmd} #{args.join(' ')}"
        if CommandLine.options[:debug].value
          CLI.blue_arrow cmd_str
          CompilerStore::LanguageCompilerVariableNames.each do |language, variables|
            Array(variables).each do |variable|
              print "#{variable}: #{ENV[variable]}\n"
            end
          end
          CompilerStore::LanguageCompilerFlagNames.each do |language, variables|
            Array(variables).each do |variable|
              print "#{variable}: #{ENV[variable]}\n"
            end
          end
          print "LDFLAGS: #{ENV['LDFLAGS']}\n"
        else
          CLI.blue_arrow cmd_str, :truncate
        end
        if not CommandLine.options[:verbose].value and not options.include? :screen_output
          cmd_str << " 1>#{ConfigStore.package_root}/stdout.#{Process.pid}" +
                     " 2>#{ConfigStore.package_root}/stderr.#{Process.pid}"
        end
        system sources + cmd_str
        if not $?.success? and not options.include? :skip_error
          CLI.report_error "Failed to run #{cmd_str}.\n"
        end
        CompilerStore.unset_flags
      end

      def url_exist? url
        uri = URI(url)
        begin
          request = Net::HTTP.new uri.host
          response= request.request_head uri.path
          response.code.to_i == 200
        rescue
        end
      end
    end
  end
end
