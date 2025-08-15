{
  description = "Nix flake for libyal/liblnk: build and dev shell for the Windows .LNK library and tools.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    # Upstream source of liblnk (non-flake); the lock file will pin a concrete revision.
    liblnk-src = {
      url = "github:libyal/liblnk";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, liblnk-src }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        lib = pkgs.lib;
        pname = "liblnk";
        version = "unstable-" + (liblnk-src.rev or "unlocked");
      in
      {
        packages.${pname} = pkgs.stdenv.mkDerivation {
          inherit pname version;
          src = liblnk-src;

          nativeBuildInputs = with pkgs; [
            git autoconf automake libtool pkg-config gettext
          ];

          buildInputs = with pkgs; [
            zlib
          ] ++ lib.optionals pkgs.stdenv.isDarwin [ pkgs.libiconv ];

          configurePhase = ''
            runHook preConfigure
            ./synclibs.sh
            ./autogen.sh
            ./configure --prefix=$out
            runHook postConfigure
          '';

          buildPhase = "make";
          installPhase = "make install";

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
          nativeBuildInputs = with pkgs; [
            autoconf automake libtool pkg-config gettext
          ];
          buildInputs = with pkgs; [
            zlib
          ] ++ lib.optionals pkgs.stdenv.isDarwin [ pkgs.libiconv ];
        };
      });
}
