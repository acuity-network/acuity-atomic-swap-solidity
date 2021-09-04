#!/usr/bin/env bash

set -e

./scripts/build.sh
geth attach --exec "eth.sendTransaction({from:eth.coinbase, to:\"0xa686954df1a23c379a9ce4b37b18c60f9a8e8c2f\", value: web3.toWei(1000, \"ether\")});" /tmp/geth.ipc
mkdir -p ~/.ethereum/keystore/
cp ./scripts/UTC--2021-09-03T23-02-54.725253244Z--a686954df1a23c379a9ce4b37b18c60f9a8e8c2f ~/.ethereum/keystore/
export ETH_FROM=0xa686954df1a23c379a9ce4b37b18c60f9a8e8c2f
export ETH_PASSWORD=./scripts/password
export ETH_GAS=2000000
. ~/.nix-profile/etc/profile.d/nix.sh
dapp create AcuityAtomicSwapSell
dapp create AcuityAtomicSwapBuy
