#!/bin/bash

set -e

echo "dckr_pat_nwSypHyWzV_SgLpYIBqm0b0mzFg" | docker login -u rafaelrpsantos --password-stdin

docker compose -f compose-umdrive.yml up -d
