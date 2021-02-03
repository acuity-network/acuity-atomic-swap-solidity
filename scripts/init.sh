#!/usr/bin/env bash

set -e

echo "*** Initializing Dapp Tools"

curl -L https://nixos.org/nix/install | sh
. ~/.nix-profile/etc/profile.d/nix.sh
curl https://dapp.tools/install | sh
