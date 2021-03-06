module STARMAN
  class PackageBinary
    extend System::Command
    extend FileUtils

    class << self
      def read_record package
        file = record_file package
        File.exist?(file) ? YAML.load(File.open(file, 'r').read) : {}
      end

      def write_record package
        file = record_file package
        record = File.exist?(file) ? YAML.load(File.open(file, 'r').read) : {}
        sha = Digest::SHA256.hexdigest(File.read "#{ConfigStore.package_root}/#{package.tag}.tgz")
        record[sha] = package.tag
        CLI.report_notice "Record binary #{CLI.blue package.tag}."
        File.open(file, 'w').write record.to_yaml
      end

      def has? package
        _package = package.group_master || package
        record = PackageBinary.read_record _package
        not record.empty? and Storage.uploaded? _package
      end

      def match? package
        _package = package.group_master || package
        record = PackageBinary.read_record _package
        file_path = "#{ConfigStore.package_root}/#{Storage.tar_name _package}"
        File.exist? file_path and record.keys.include? Digest::SHA256.hexdigest(File.read file_path)
      end

      def run package
        return false if PackageInstaller.installed? package
        package.pre_install
        if package.has_label? :external_binary
          external_binary package
        else
          if package.group_master
            master_binary package
          else
            normal_binary package
          end
        end
        package.post_install
      end

      protected

      def record_file package
        "#{ENV['STARMAN_ROOT']}/packages/binary/#{package.name}.yml"
      end

      def external_binary package
        CLI.report_notice "Install external binary package #{CLI.blue package.name}."
        mkdir_p package.prefix do
          decompress "#{ConfigStore.package_root}/#{package.external_binary.filename}"
          PackageProfile.write_profile package
        end
      end

      def master_binary package
        CLI.report_notice "Install precompiled package #{CLI.blue package.group_master.name}."
        mkdir_p package.prefix do
          decompress "#{ConfigStore.package_root}/#{Storage.tar_name package.group_master}"
        end
      end

      def normal_binary package
        CLI.report_notice "Install precompiled package #{CLI.blue package.name}."
        mkdir_p package.prefix do
          decompress "#{ConfigStore.package_root}/#{Storage.tar_name package}"
        end
      end
    end
  end
end
