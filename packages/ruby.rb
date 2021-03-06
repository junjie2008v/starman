module STARMAN
  class Ruby < Package
    homepage 'https://www.ruby-lang.org/'
    url 'https://cache.ruby-lang.org/pub/ruby/2.3/ruby-2.3.3.tar.bz2'
    sha256 '882e6146ed26c6e78c02342835f5d46b86de95f0dc4e16543294bc656594cc5b'
    version '2.3.3'

    def abi_version
      '2.3.0'
    end

    label :compiler_agnostic

    # Reverts an upstream commit which incorrectly tries to install headers
    # into SDKROOT, if defined
    # See https://bugs.ruby-lang.org/issues/11881
    # The issue has been fixed on HEAD as of 1 Jan 2016, but has not been
    # backported to the 2.3 branch yet and patch is still required.
    patch do
      url 'https://raw.githubusercontent.com/Homebrew/formula-patches/ba8cc6b88e6b7153ac37739e5a1a6bbbd8f43817/ruby/mkconfig.patch'
      sha256 '929c618f74e89a5e42d899a962d7d2e4af75716523193af42626884eaba1d765'
    end

    depends_on :pkgconfig if needs_build?
    depends_on :readline
    depends_on :gmp
    depends_on :libyaml
    depends_on :openssl

    def export_env
      System::Shell.prepend 'PATH', "#{persist}/bin", separator: ':', system: true
    end

    def install
      ENV.delete 'SDKROOT'
      args = %W[
        --prefix=#{prefix}
        --enable-shared
        --disable-silent-rules
        --with-sitedir=#{persist}/lib/ruby/site_ruby
        --with-vendordir=#{persist}/lib/ruby/vendor_ruby
        --with-opt-dir=#{Readline.prefix}:#{Gmp.prefix}:#{Libyaml.prefix}:#{Openssl.prefix}
      ]
      args << '--with-out-ext=tk'
      args << '--disable-install-doc'

      run './configure', *args

      # These directories are empty on install; sitedir is used for non-rubygems
      # third party libraries, and vendordir is used for packager-provided libraries.
      inreplace 'tool/rbinstall.rb' do |s|
        s.gsub! 'prepare "extension scripts", sitelibdir', ''
        s.gsub! 'prepare "extension scripts", vendorlibdir', ''
        s.gsub! 'prepare "extension objects", sitearchlibdir', ''
        s.gsub! 'prepare "extension objects", vendorarchlibdir', ''
      end

      run 'make'
      run 'make', 'install'
    end

    def post_install
      write_file "#{lib}/ruby/#{abi_version}/rubygems/defaults/operating_system.rb", rubygems_config
    end

    def rubygems_config; <<-EOT.keep_indent
      module Gem
        class << self
          alias :old_default_dir :default_dir
          alias :old_default_path :default_path
          alias :old_default_bindir :default_bindir
          alias :old_ruby :ruby
        end

        def self.default_dir
          path = [
            "#{persist}",
            "lib",
            "ruby",
            "gems",
            "#{abi_version}"
          ]

          @default_dir ||= File.join(*path)
        end

        def self.private_dir
          path = if defined? RUBY_FRAMEWORK_VERSION then
                   [
                     File.dirname(RbConfig::CONFIG['sitedir']),
                     'Gems',
                     RbConfig::CONFIG['ruby_version']
                   ]
                 elsif RbConfig::CONFIG['rubylibprefix'] then
                   [
                    RbConfig::CONFIG['rubylibprefix'],
                    'gems',
                    RbConfig::CONFIG['ruby_version']
                   ]
                 else
                   [
                     RbConfig::CONFIG['libdir'],
                     ruby_engine,
                     'gems',
                     RbConfig::CONFIG['ruby_version']
                   ]
                 end

          @private_dir ||= File.join(*path)
        end

        def self.default_path
          if Gem.user_home && File.exist?(Gem.user_home)
            [user_dir, default_dir, private_dir]
          else
            [default_dir, private_dir]
          end
      end

        def self.default_bindir
          "#{persist}/bin"
        end

        def self.ruby
          "#{bin}/ruby"
        end
      end
      EOT
    end
  end
end
