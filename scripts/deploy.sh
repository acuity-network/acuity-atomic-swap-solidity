#!/usr/bin/env bash

set -e

./scripts/build.sh
. ~/.nix-profile/etc/profile.d/nix.sh

geth attach --exec "eth.sendTransaction({from:eth.coinbase, to:\"0xa686954df1a23c379a9ce4b37b18c60f9a8e8c2f\", value: web3.toWei(1000, \"ether\")});" /tmp/acuity1.ipc
geth attach --exec "eth.sendTransaction({from:eth.coinbase, to:\"0xc5f65590b17A3131E86690B789Ac78190Ac4554D\", value: web3.toWei(1, \"ether\")});" /tmp/acuity1.ipc
geth attach --exec "eth.sendTransaction({from:eth.coinbase, to:\"0xf276CBD4eb65817B66D9e25D34e150B40d8de581\", value: web3.toWei(100, \"ether\")});" /tmp/acuity1.ipc
mkdir -p ~/.ethereum/keystore/
cp ./scripts/UTC--2021-09-03T23-02-54.725253244Z--a686954df1a23c379a9ce4b37b18c60f9a8e8c2f ~/.ethereum/keystore/
export ETH_RPC_URL=http://127.0.0.1:8545
export ETH_FROM=0xa686954df1a23c379a9ce4b37b18c60f9a8e8c2f
export ETH_PASSWORD=./scripts/password
export ETH_GAS=2000000
dapp create AcuityAtomicSwapSell
dapp create AcuityAtomicSwapBuy


geth attach --exec "eth.sendTransaction({from:eth.coinbase, to:\"0xa686954df1a23c379a9ce4b37b18c60f9a8e8c2f\", value: web3.toWei(1000, \"ether\")});" /tmp/acuity2.ipc
geth attach --exec "eth.sendTransaction({from:eth.coinbase, to:\"0xc5f65590b17A3131E86690B789Ac78190Ac4554D\", value: web3.toWei(1, \"ether\")});" /tmp/acuity2.ipc
geth attach --exec "eth.sendTransaction({from:eth.coinbase, to:\"0xf276CBD4eb65817B66D9e25D34e150B40d8de581\", value: web3.toWei(100, \"ether\")});" /tmp/acuity2.ipc
mkdir -p ~/.ethereum/keystore/
cp ./scripts/UTC--2021-09-03T23-02-54.725253244Z--a686954df1a23c379a9ce4b37b18c60f9a8e8c2f ~/.ethereum/keystore/
export ETH_RPC_URL=http://127.0.0.1:8547
export ETH_FROM=0xa686954df1a23c379a9ce4b37b18c60f9a8e8c2f
export ETH_PASSWORD=./scripts/password
export ETH_GAS=2000000
dapp create AcuityAtomicSwapSell
dapp create AcuityAtomicSwapBuy
