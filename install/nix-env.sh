#!/bin/sh
nix-env -iA nixos.uutils-coreutils
nix-env -i tokei
nix-env --install ripgrep
