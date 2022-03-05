#!/usr/bin/env bash

set -e

. ~/.nix-profile/etc/profile.d/nix.sh
export DAPP_BUILD_OPTIMIZE_RUNS=10000
dapp --use solc:0.8.12 --verbose --optimize test
