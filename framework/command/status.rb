module STARMAN
  module Command
    class Status
      def self.accepted_options
        {}
      end

      def self.run
        CommandLine.packages.each_value do |package|
          next if not package.respond_to? :status
          case package.status
          when :on
            CLI.report_notice "#{CLI.blue package.name} is #{CLI.green 'on'}."
          when :off
            CLI.report_notice "#{CLI.blue package.name} is #{CLI.red 'off'}."
          end
        end
      end
    end
  end
end
