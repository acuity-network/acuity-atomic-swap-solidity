#!/usr/bin/env bash

set -e

./scripts/build.sh
mkdir -p ~/.ethereum/keystore/
cp ./scripts/UTC--2021-09-03T23-02-54.725253244Z--a686954df1a23c379a9ce4b37b18c60f9a8e8c2f ~/.ethereum/keystore/
export ETH_FROM=0xa686954df1a23c379a9ce4b37b18c60f9a8e8c2f
export ETH_PASSWORD=./scripts/password
export ETH_GAS=2000000
export ETH_RPC_URL=https://rpc-mumbai.maticvigil.com
. ~/.nix-profile/etc/profile.d/nix.sh
dapp create AcuityAccount
dapp create AcuityAtomicSwap
