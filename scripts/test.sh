#!/usr/bin/env bash

set -e

. ~/.nix-profile/etc/profile.d/nix.sh
export DAPP_SOLC=/usr/bin/solc
dapp test
