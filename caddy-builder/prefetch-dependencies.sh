#!/bin/sh
set -e # exit on failure

echo "Prefetching dependencies"

echo "Getting Caddy dependenices"
cd /am-caddy-builder/caddy
go get -d -v ./...

echo "Getting Caddy Rest Storage dependenices"
cd /am-caddy-builder/caddy_rest_storage
go get -d -v ./...

echo "Getting Caddy Admin Repeat dependenices"
cd /am-caddy-builder/caddy-admin-repeat
go get -d -v ./...

echo "Finished Prefetching dependenices"
