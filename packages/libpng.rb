module STARMAN
  class Libpng < Package
    homepage 'http://www.libpng.org/pub/png/libpng.html'
    url 'https://sourceforge.net/projects/libpng/files/libpng16/1.6.26/libpng-1.6.26.tar.xz'
    sha256 '266743a326986c3dbcee9d89b640595f6b16a293fd02b37d8c91348d317b73f9'
    version '1.6.26'

    label :compiler_agnostic
    label :system_conflict

    def install
      args = %W[
        --disable-dependency-tracking
        --disable-silent-rules
        --prefix=#{prefix}
      ]
      run './configure', *args
      run 'make'
      run 'make', 'test'
      run 'make', 'install'
    end
  end
end
