{
  description = "Nix flake for libyal/liblnk: build and dev shell for the Windows .LNK library and tools.";

  inputs = {
    nixpkgs.url     = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";

    liblnk-src = {
      url = "github:libyal/liblnk";
      flake = false;
    };

    # Additional dependencies that synclibs.sh would normally download
    libbfio-src = { url = "github:libyal/libbfio"; flake = false; };
    libcdata-src = { url = "github:libyal/libcdata"; flake = false; };
    libcerror-src = { url = "github:libyal/libcerror"; flake = false; };
    libcfile-src = { url = "github:libyal/libcfile"; flake = false; };
    libclocale-src = { url = "github:libyal/libclocale"; flake = false; };
    libcnotify-src = { url = "github:libyal/libcnotify"; flake = false; };
    libcpath-src = { url = "github:libyal/libcpath"; flake = false; };
    libcsplit-src = { url = "github:libyal/libcsplit"; flake = false; };
    libcthreads-src = { url = "github:libyal/libcthreads"; flake = false; };
    libfdatetime-src = { url = "github:libyal/libfdatetime"; flake = false; };
    libfguid-src = { url = "github:libyal/libfguid"; flake = false; };
    libfole-src = { url = "github:libyal/libfole"; flake = false; };
    libfwps-src = { url = "github:libyal/libfwps"; flake = false; };
    libfwsi-src = { url = "github:libyal/libfwsi"; flake = false; };
    libuna-src = { url = "github:libyal/libuna"; flake = false; };
  };

  outputs = { self, nixpkgs, flake-utils, liblnk-src, libbfio-src, libcdata-src, libcerror-src, libcfile-src, libclocale-src, libcnotify-src, libcpath-src, libcsplit-src, libcthreads-src, libfdatetime-src, libfguid-src, libfole-src, libfwps-src, libfwsi-src, libuna-src }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        lib  = pkgs.lib;

        pname   = "liblnk";
        version = "unstable-" + (liblnk-src.rev or "unlocked");

        commonNativeBuildInputs = with pkgs; [
          git autoreconfHook pkg-config gettext
        ];
        commonBuildInputs = with pkgs; [
          zlib
        ] ++ lib.optionals pkgs.stdenv.isDarwin [ pkgs.libiconv ];
      in
      {
        packages.${pname} = pkgs.stdenv.mkDerivation {
          inherit pname version;
          src = liblnk-src;

          nativeBuildInputs = commonNativeBuildInputs;
          buildInputs       = commonBuildInputs;

          preAutoreconf = ''
            # Instead of running ./synclibs.sh which requires network access,
            # copy the libyal dependencies from the flake inputs
            
            # Map of library names to their source inputs
            declare -A lib_sources=(
              ["libbfio"]="${libbfio-src}"
              ["libcdata"]="${libcdata-src}" 
              ["libcerror"]="${libcerror-src}"
              ["libcfile"]="${libcfile-src}"
              ["libclocale"]="${libclocale-src}"
              ["libcnotify"]="${libcnotify-src}"
              ["libcpath"]="${libcpath-src}"
              ["libcsplit"]="${libcsplit-src}"
              ["libcthreads"]="${libcthreads-src}"
              ["libfdatetime"]="${libfdatetime-src}"
              ["libfguid"]="${libfguid-src}"
              ["libfole"]="${libfole-src}"
              ["libfwps"]="${libfwps-src}"
              ["libfwsi"]="${libfwsi-src}"
              ["libuna"]="${libuna-src}"
            )

            for lib in "''${!lib_sources[@]}"; do
              lib_src="''${lib_sources[$lib]}"
              echo "Setting up $lib from $lib_src"
              
              # Create the library directory
              mkdir -p "$lib"
              
              # Copy the library source files
              if [ -d "$lib_src/$lib" ]; then
                cp "$lib_src/$lib"/*.[chly] "$lib/" 2>/dev/null || true
                cp "$lib_src/$lib/Makefile.am" "$lib/" 2>/dev/null || true
              fi
              
              # Get version from configure.ac
              if [ -f "$lib_src/configure.ac" ]; then
                lib_version=$(grep -A 2 AC_INIT "$lib_src/configure.ac" | tail -n 1 | sed 's/^[[:space:]]*\[\([0-9]*\)\],[[:space:]]*$/\1/' 2>/dev/null || echo "1")
              else
                lib_version="1"
              fi
              
              # Create the definitions header if template exists
              if [ -f "$lib_src/$lib/''${lib}_definitions.h.in" ]; then
                sed "s/@VERSION@/$lib_version/" "$lib_src/$lib/''${lib}_definitions.h.in" > "$lib/''${lib}_definitions.h"
              fi
              
              # Apply the same transformations that synclibs.sh would do to Makefile.am
              if [ -f "$lib/Makefile.am" ]; then
                lib_upper=$(echo "$lib" | tr '[a-z]' '[A-Z]')
                
                # Add the conditional wrapper for local builds
                sed -i "1i\\
if HAVE_LOCAL_$lib_upper" "$lib/Makefile.am"
                echo "endif" >> "$lib/Makefile.am"
                
                # Change lib_LTLIBRARIES to noinst_LTLIBRARIES 
                sed -i 's/lib_LTLIBRARIES/noinst_LTLIBRARIES/' "$lib/Makefile.am"
                
                # Remove the main library source file (it would conflict)
                sed -i "/''${lib}\.c/d" "$lib/Makefile.am"
                
                # Remove EXTRA_DIST sections that reference external files
                sed -i '/EXTRA_DIST = /,/^$/d' "$lib/Makefile.am"
                
                # Remove references to .rc files and other Windows-specific files
                sed -i "/''${lib}\\.rc/d" "$lib/Makefile.am"
                sed -i "/''${lib}_definitions\\.h\\.in/d" "$lib/Makefile.am"
              fi
              
              # Remove the main library source file if it exists (to avoid conflicts)
              rm -f "$lib/$lib.c"
            done
          '';

          meta = with lib; {
            description = "Library and tools for parsing Windows .LNK (shell shortcut) files";
            homepage    = "https://github.com/libyal/liblnk";
            license     = licenses.lgpl3Plus;
            maintainers = [];
            platforms   = platforms.unix;
          };
        };

        packages.default = self.packages.${system}.${pname};

        devShells.default = pkgs.mkShell {
          nativeBuildInputs = commonNativeBuildInputs;
          buildInputs       = commonBuildInputs;
        };
      });
}
