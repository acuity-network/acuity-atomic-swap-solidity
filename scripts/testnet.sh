#!/usr/bin/env bash

set -e

geth --dev --http --http.corsdomain "*" --ws
