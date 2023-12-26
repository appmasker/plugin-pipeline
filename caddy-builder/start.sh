#!/bin/bash

set -e # exit on failure

CADDY_VERSION=v2.7.6

echo "Making repos dir"
rm -rf repos
mkdir -p repos
cd repos

# clone everything in parallel
echo "Cloning repos"
git clone https://github.com/caddyserver/caddy &
git clone https://github.com/appmasker/caddy_rest_storage --single-branch --depth 1 &
git clone "https://oauth2:$GITHUB_APPMASKER_TOKEN@github.com/appmasker/caddy-admin-repeat" --single-branch --depth 1 &
wait

echo "Checking out Caddy $CADDY_VERSION"
cd ./caddy && git checkout $CADDY_VERSION 
cd ..

# go back to root
cd ..

docker buildx build . -t appmasker/prefetch-deps:$CADDY_VERSION --progress=plain --platform linux/amd64,linux/arm64 --push

echo "Cleaning up"
rm -rf ./repos

echo "Done building prefetch deps image"
