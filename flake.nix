{
  description = "Nix flake for libyal/liblnk: build and dev shell for the Windows .LNK library and tools.";

  inputs = {
    nixpkgs.url     = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";

    liblnk-src = {
      url = "github:libyal/liblnk";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, liblnk-src }:
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
