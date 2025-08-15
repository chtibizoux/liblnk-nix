# liblnk-nix

Nix flake that packages libyal/liblnk — a library and tools for parsing Windows `.LNK` (shell shortcut) files — providing:
- a reproducible build (`nix build`)
- a development shell with all tooling (`nix develop`)
- CI that runs flake checks and builds on Linux and macOS

## Usage

Build the library and tools:
```sh
nix build .#liblnk
```

Enter a dev shell (autotools, pkg-config, etc. preinstalled):
```sh
nix develop
```

### Pinning the upstream source
This flake fetches the upstream source via an input (`liblnk-src`). After the first run, your `flake.lock` will pin an exact revision. To update or pin to a specific commit:
```sh
# Update to the latest default-branch commit
nix flake update liblnk-src

# Or pin to a specific commit
nix flake lock --update-input liblnk-src --override-input liblnk-src github:libyal/liblnk?rev=<commit-sha>
```

## CI

GitHub Actions workflow builds on Ubuntu and macOS and runs `nix flake check` and `nix build`.

## License

This repository (the flake and CI) is provided under permissive terms — the upstream `liblnk` project is licensed under LGPL-3.0-or-later. See https://github.com/libyal/liblnk for details.
