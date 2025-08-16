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
            # Set up libyal dependencies from Nix flake inputs
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

            # Copy dependency sources to writable temporary directories for synclibs.sh to use
            for lib in "''${!lib_sources[@]}"; do
              lib_src="''${lib_sources[$lib]}"
              echo "Setting up $lib from $lib_src"
              
              # Copy the source to a writable temporary directory that synclibs.sh expects
              cp -r "$lib_src" "$lib-$$"
              # Make the copied files writable since Nix store files are read-only
              chmod -R u+w "$lib-$$"
            done
            
            # Create a modified synclibs.sh that skips git operations but keeps all transformation logic
            cp synclibs.sh synclibs-nix.sh
            
            # Replace git clone with a no-op comment
            sed -i 's/git clone --quiet ${GIT_URL} ${LOCAL_LIB}-$$;/# Git clone replaced - using Nix flake input/' synclibs-nix.sh
            
            # Remove git fetch and git checkout commands 
            sed -i '/cd ${LOCAL_LIB}-$$ && git fetch/d' synclibs-nix.sh
            sed -i '/cd ${LOCAL_LIB}-$$ && git checkout/d' synclibs-nix.sh
            
            # Replace version detection with a simple fallback since we'll get latest
            sed -i 's/LATEST_TAG=`cd ${LOCAL_LIB}-$$ && git describe --tags --abbrev=0`;/LATEST_TAG=""/' synclibs-nix.sh
            
            # Run the modified script
            ./synclibs-nix.sh
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
