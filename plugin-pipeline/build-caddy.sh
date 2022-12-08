#!/bin/sh

echo "Starting build-caddy script"

eval APPMASKER_ACCESS_TOKEN="$1"
eval ACCESS_TOKEN_USR="$2"
eval ACCESS_TOKEN_PWD="$3"
eval PLUGIN_REPOS="$4"

echo "Cloning AppMasker repos"

git clone "https://oauth2:${APPMASKER_ACCESS_TOKEN}@github.com/appmasker/caddy-admin-repeat" --single-branch --depth 1
git clone "https://oauth2:${APPMASKER_ACCESS_TOKEN}@github.com/appmasker/caddy_rest_storage" --single-branch --depth 1

echo "Done cloning repos. Assembling user plugins."

getPluginReposFlags() {
  REPOFLAGS=""
  for repo in ${PLUGIN_REPOS//,/ }
    do
      REPOFLAGS+=" --with ${repo}"
    done
  echo "${REPOFLAGS}"
}

eval "xcaddy build v2.6.0 \
  $(getPluginReposFlags) \
  --with github.com/appmasker/caddy-admin-repeat=./caddy-admin-repeat \
  --with github.com/appmasker/caddy_rest_storage=./caddy_rest_storage"
