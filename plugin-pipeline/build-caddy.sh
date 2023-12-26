#!/bin/sh
set -e # exit on failure

echo "Starting build-caddy script"

eval GITHUB_APPMASKER_TOKEN="$1"
eval ACCESS_TOKEN_USR="$2"
eval ACCESS_TOKEN_PWD="$3"
eval PLUGIN_REPOS="$4"

echo "Cloning AppMasker repos in parallel"

git clone "https://oauth2:${GITHUB_APPMASKER_TOKEN}@github.com/appmasker/caddy-admin-repeat" --single-branch --depth 1 &
git clone "https://github.com/appmasker/caddy_rest_storage" --single-branch --depth 1 &

echo "Done cloning repos. Assembling user plugins."

# gather user's plugin modules

MODULE_FLAGS=""

if [ "$ACCESS_TOKEN_PWD" != "nothing" ]; then
  echo "Cloning user repos in parallel with oauth2 token"
  for repo in ${PLUGIN_REPOS//,/ }
    do
      echo "Processing repo: $repo"
      git clone "https://oauth2:${ACCESS_TOKEN_PWD}@${repo}" --single-branch --depth 1 &
      
      path=$(basename "$repo")
      MODULE_FLAGS="$MODULE_FLAGS --with $repo=./$path"
    done

  echo "Done cloning repos with oauth2 token. Assembling user plugins."
else
  echo "No oauth2 token provided."
  for repo in ${PLUGIN_REPOS//,/ }
    do
      MODULE_FLAGS="$MODULE_FLAGS --with $repo"
    done

fi

wait

BUILD_COMMAND="xcaddy build v2.7.6 \
  $MODULE_FLAGS \
  --with github.com/appmasker/caddy-admin-repeat=./caddy-admin-repeat \
  --with github.com/appmasker/caddy_rest_storage=./caddy_rest_storage"

echo "FINAL COMMAND: $BUILD_COMMAND"

eval "$BUILD_COMMAND"
