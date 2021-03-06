module STARMAN
  class PackageInstaller
    extend System::Command
    extend FileUtils

    class << self
      def installed? package
        if package.has_label? :parasite
          profile = PackageProfile.read_profile PackageLoader.packages[package.labels[:parasite][:into]][:instance]
          sha256 = profile.fetch(:parasites, {}).fetch(package.name, {}).fetch(:sha256, nil)
        else
          profile = PackageProfile.read_profile package
          sha256 = profile[:sha256]
        end
        if package.has_label? :external_binary
          sha256 == package.external_binary.sha256
        else
          sha256 == package.sha256
        end
      end

      def run package
        return false if installed? package
        CLI.report_notice "Install package #{CLI.blue package.name}."
        dir = "#{ConfigStore.package_root}/#{package.name}"
        mkdir dir, force: true
        work_in dir do
          decompress "#{ConfigStore.package_root}/#{package.filename}"
          subdirs = Dir.glob('*')
          if subdirs.size == 1
            work_in subdirs[0] do
              package.patches.each_with_index do |patch, index|
                case patch
                when String
                  CLI.report_notice "Apply patch #{CLI.green "##{index}"} to #{CLI.blue package.name}."
                  patch_data patch
                when PackageSpec
                  CLI.report_notice "Apply patch #{CLI.green "##{index}"} to #{CLI.blue package.name}."
                  patch_file "#{ConfigStore.package_root}/#{package.name}.patch.#{index}"
                when Array
                  mkdir 'starman.patch' do
                    decompress "#{ConfigStore.package_root}/#{patch.first.filename}"
                  end
                  patch_dir = Dir.glob('starman.patch/*')[0]
                  patch.last.each do |file|
                    CLI.report_notice "Apply patch #{CLI.green file} to #{CLI.blue package.name}"
                    patch_file "#{patch_dir}/#{file}"
                  end
                end
              end
              package.pre_install
              package.install
              package.post_install
              PackageProfile.write_profile package
            end
          else
            CLI.report_error "There are multiple directories in #{CLI.red dir}."
          end
        end
        rm_r dir
      end
    end
  end
end
