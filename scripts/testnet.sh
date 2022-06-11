#!/usr/bin/env bash

set -e

geth --dev --ipcpath /tmp/acuity-dex-testnet.ipc --http --http.port 8545 --http.corsdomain "*" --ws --ws.port 8546
