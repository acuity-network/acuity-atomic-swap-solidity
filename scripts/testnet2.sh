#!/usr/bin/env bash

set -e

geth --dev --ipcpath /tmp/acuity2.ipc --http --http.port 8547 --http.corsdomain "*" --ws --ws.port 8548
