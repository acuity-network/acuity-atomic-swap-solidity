#!/usr/bin/env bash

set -e

. ~/.nix-profile/etc/profile.d/nix.sh
export DAPP_SOLC=/usr/bin/solc
dapp --use solc:0.8.3 test --verbose
