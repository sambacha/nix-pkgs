#!/bin/bash
## nix-shell script to make derivations persistant, and avoid Nix garbage collection
#
## Usage
# p-shell followed by the path to the Nix shell definition. This will create a gc-root in the parent directory of the Nix shell.
#
## Example: p-shell ~/shells/node-build.nix


set -ex

FILE=$1
FILE_PATH=$(realpath "$FILE")
DIR_PATH=$(dirname "$FILE_PATH")
BASE=$(basename "$FILE_PATH")
DER_PATH=$DIR_PATH/derivation_$BASE

mkdir -p "$DER_PATH"/shell-deps/

nix-instantiate "$FILE_PATH" --indirect --add-root "$DER_PATH"/shell.drv
nix-store -r "$(nix-store --query --references "$DER_PATH"/shell.drv)" \
  --indirect --add-root "$DER_PATH"/shell-deps/shell.dep
nix-shell "$FILE"
