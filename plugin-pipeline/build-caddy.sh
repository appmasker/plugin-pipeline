#!/bin/sh
set -e # exit on failure

echo "Starting build-caddy script"

eval GITHUB_APPMASKER_TOKEN="$1"
eval ACCESS_TOKEN_USR="$2"
eval ACCESS_TOKEN_PWD="$3"
eval PLUGIN_REPOS="$4"

echo "Cloning AppMasker repos"

git clone "https://oauth2:${GITHUB_APPMASKER_TOKEN}@github.com/appmasker/caddy-admin-repeat" --single-branch --depth 1
git clone "https://oauth2:${GITHUB_APPMASKER_TOKEN}@github.com/appmasker/caddy_rest_storage" --single-branch --depth 1

echo "Done cloning repos. Assembling user plugins."

getPluginModules() {
  MODULE_FLAGS=""
  for repo in ${PLUGIN_REPOS//,/ }
    do
      MODULE_FLAGS="$MODULE_FLAGS --with $repo"
    done
  echo "$MODULE_FLAGS"
}

BUILD_COMMAND="xcaddy build v2.6.0 \
  $(getPluginModules) \
  --with github.com/appmasker/caddy-admin-repeat=./caddy-admin-repeat \
  --with github.com/appmasker/caddy_rest_storage=./caddy_rest_storage"

echo "FINAL COMMAND: $BUILD_COMMAND"

eval "$BUILD_COMMAND"
