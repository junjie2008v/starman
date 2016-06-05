module STARMAN
  class PackageLoader
    @@packages = {}
    Dir.glob("#{ENV['STARMAN_ROOT']}/packages/*.rb").each do |file|
      name = File.basename(file, '.rb').to_sym
      @@packages[name] = { :file => file }
    end

    def self.transfer_command_line_options_to package
      # Check command line options for package options.
      CommandLine.options.each do |name, value|
        next unless package.options.has_key? name
        begin
          if value.class == String
            package.options[name].check value
            CommandLine.options[name] = package.options[name]
          else
            package.options[name] = value
          end
        rescue => e
          CLI.report_error "Package option #{CLI.red name}: #{e}"
        end
      end
    end

    def self.load_package name, *options
      return if packages[name][:instance] and not options.include? :force
      Package.clean name
      load packages[name][:file]
      package = eval("#{name.to_s.capitalize}").new
      transfer_command_line_options_to package
      # Reload package, since the options may change dependencies.
      Package.clean name
      load packages[name][:file]
      package = eval("#{name.to_s.capitalize}").new
      # Connect group master and slave.
      if package.group_master
        package.group_master packages[package.group_master][:instance]
        package.group_master.slave package
      end
      CommandLine.packages[name] = package # Record the package to install.
      packages[name][:instance] = package
      package.dependencies.each do |depend_name, options|
        # TODO: Change package.dependencies.
        depend_name = PackageAlias.lookup depend_name if not packages.has_key? depend_name
        load_package depend_name, options
      end
    end

    def self.run
      CommandLine.packages.keys.each do |name|
        load_package name.to_s.downcase.to_sym
      end
    end

    def self.has_package? name
      @@packages.has_key? name.to_s.downcase.to_sym
    end

    def self.packages
      @@packages
    end

    def self.installed_packages
      if not defined? @@installed_packages
        @@installed_packages ||= {}
        Dir.glob("#{ConfigStore.install_root}/*").each do |dir|
          next if not File.directory? dir
          name = File.basename(dir).to_sym
          load_package name
          package = packages[name][:instance]
          @@installed_packages[name] = package
          if package.has_label? :group_master
            package.slaves.each do |slave|
              @@installed_packages[slave.name] = slave
            end
          end
        end
      end
      @@installed_packages
    end
  end
end