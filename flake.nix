{
  description = "Nix flake for libyal/liblnk: build and dev shell for the Windows .LNK library and tools.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";

    liblnk-src = {
      url = "github:libyal/liblnk";
      flake = false;
    };
    libbfio-src = {
      url = "github:libyal/libbfio";
      flake = false;
    };
    libcdata-src = {
      url = "github:libyal/libcdata";
      flake = false;
    };
    libcerror-src = {
      url = "github:libyal/libcerror";
      flake = false;
    };
    libcfile-src = {
      url = "github:libyal/libcfile";
      flake = false;
    };
    libclocale-src = {
      url = "github:libyal/libclocale";
      flake = false;
    };
    libcnotify-src = {
      url = "github:libyal/libcnotify";
      flake = false;
    };
    libcpath-src = {
      url = "github:libyal/libcpath";
      flake = false;
    };
    libcsplit-src = {
      url = "github:libyal/libcsplit";
      flake = false;
    };
    libcthreads-src = {
      url = "github:libyal/libcthreads";
      flake = false;
    };
    libfdatetime-src = {
      url = "github:libyal/libfdatetime";
      flake = false;
    };
    libfguid-src = {
      url = "github:libyal/libfguid";
      flake = false;
    };
    libfole-src = {
      url = "github:libyal/libfole";
      flake = false;
    };
    libfwps-src = {
      url = "github:libyal/libfwps";
      flake = false;
    };
    libfwsi-src = {
      url = "github:libyal/libfwsi";
      flake = false;
    };
    libuna-src = {
      url = "github:libyal/libuna";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      liblnk-src,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        lib = pkgs.lib;

        pname = "liblnk";
        version = "unstable-" + (liblnk-src.rev or "unlocked");

        commonNativeBuildInputs = with pkgs; [
          autoreconfHook
          pkg-config
          gettext
        ];
        commonBuildInputs =
          with pkgs;
          [
            zlib
          ]
          ++ lib.optionals pkgs.stdenv.isDarwin [ pkgs.libiconv ];

        deps = lib.filterAttrs (
          name: _: builtins.match ".+-src" name != null && name != "liblnk-src"
        ) self.inputs;
      in
      {
        packages.${pname} = pkgs.stdenv.mkDerivation {
          inherit pname version;
          src = liblnk-src;

          nativeBuildInputs = commonNativeBuildInputs;
          buildInputs = commonBuildInputs;

          preAutoreconf = ''
            declare -A lib_sources=(${
              builtins.concatStringsSep " " (
                builtins.map (src: "['${builtins.replaceStrings [ "-src" ] [ "" ] src}']='${deps.${src}}'") (
                  builtins.attrNames deps
                )
              )
            })

            for lib in "''${!lib_sources[@]}"; do
              lib_src="''${lib_sources[$lib]}"
              ln -s "$lib_src" "$lib-$$"
            done

            cp synclibs.sh synclibs-nix.sh

            sed -i '/git clone --quiet/d' synclibs-nix.sh
            sed -i '/git fetch/d' synclibs-nix.sh
            sed -i '/git checkout/d' synclibs-nix.sh

            sed -i 's/LATEST_TAG=.\+;/LATEST_TAG="";/' synclibs-nix.sh

            sed -i 's/exit ''${EXIT_SUCCESS};/echo "End of synclibs";/' synclibs-nix.sh

            source ./synclibs-nix.sh
          '';

          meta = with lib; {
            description = "Library and tools for parsing Windows .LNK (shell shortcut) files";
            homepage = "https://github.com/libyal/liblnk";
            license = licenses.lgpl3Plus;
            maintainers = [ ];
            platforms = platforms.unix;
          };
        };

        packages.default = self.packages.${system}.${pname};

        devShells.default = pkgs.mkShell {
          nativeBuildInputs = commonNativeBuildInputs;
          buildInputs = commonBuildInputs;
        };
      }
    );
}
