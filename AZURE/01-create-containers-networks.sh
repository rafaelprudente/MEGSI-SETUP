#!/bin/bash

set -e

if ! docker network inspect megsi-net >/dev/null 2>&1; then
  docker network create megsi-net
fi

if ! docker network inspect mtraefik-net >/dev/null 2>&1; then
  docker network create traefik-net
fi
