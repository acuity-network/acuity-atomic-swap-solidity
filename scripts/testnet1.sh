#!/usr/bin/env bash

set -e

geth --dev --ipcpath /tmp/acuity1.ipc --http --http.port 8545 --http.corsdomain "*" --ws --ws.port 8546
