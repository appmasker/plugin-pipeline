#!/bin/sh
set -e # exit on failure

echo "Starting build-and-run Caddy script in ${ENVIRONMENT} env"

HOST=""
if [ $ENVIRONMENT == "production" ]
then
   HOST="https://api.appmasker.com"
elif [ $ENVIRONMENT == "development"  ]
then
   HOST="https://api-dev.appmasker.com"
elif [ $ENVIRONMENT == "local" ]
then  
  HOST="http://host.docker.internal:3000"
fi

echo "Getting Caddy build variables from AppMasker"

auth_header="--header=x-api-key: ${X_API_KEY}"
wget "$auth_header" "${HOST}/server/build" -O caddy-build.json

GITHUB_APPMASKER_TOKEN=$(jq -r .GITHUB_APPMASKER_TOKEN caddy-build.json)
ACCESS_TOKEN_USR=$(jq -r .ACCESS_TOKEN_USR caddy-build.json)
ACCESS_TOKEN_PWD=$(jq -r .ACCESS_TOKEN_PWD caddy-build.json)
PLUGIN_REPOS=$(jq -r .PLUGIN_REPOS caddy-build.json)

GOPRIVATE=github.com/$ACCESS_TOKEN_USR/*

echo "Token: ${GITHUB_APPMASKER_TOKEN}"
echo "Creating .netrc"

printf "machine github.com\n\
    login ${ACCESS_TOKEN_USR}\n\
    password ${ACCESS_TOKEN_PWD}\n\
    \n\
    machine api.github.com\n\
    login ${ACCESS_TOKEN_USR}\n\
    password ${ACCESS_TOKEN_PWD}\n" \
    >> /root/.netrc

chmod 600 /root/.netrc

echo "Cloning AppMasker repos in parallel"

git clone "https://oauth2:${GITHUB_APPMASKER_TOKEN}@github.com/appmasker/caddy-admin-repeat" --single-branch --depth 1 &
git clone "https://github.com/appmasker/caddy_rest_storage" --single-branch --depth 1 &
wait

echo "Done cloning repos. Assembling user plugins."

getPluginModules() {
  MODULE_FLAGS=""
  for repo in ${PLUGIN_REPOS//,/ }
    do
      MODULE_FLAGS="$MODULE_FLAGS --with $repo"
    done
  echo "$MODULE_FLAGS"
}

echo "Building Caddy with xCaddy"

BUILD_COMMAND="xcaddy build \
  $(getPluginModules) \
  --with github.com/appmasker/caddy-admin-repeat=./caddy-admin-repeat \
  --with github.com/appmasker/caddy_rest_storage=./caddy_rest_storage"
# BUILD_COMMAND="xcaddy build 6e6557926cf8cf732f0a3cb802a15878d8976690 \
#   $(getPluginModules) \
#   --with github.com/appmasker/caddy-admin-repeat@07155b787c4c4c92f2fc58924f509198cfaf996d \
#   --with github.com/appmasker/caddy_rest_storage@77f64b11c270d63d559618b0a1eca87d695de038"

eval "$BUILD_COMMAND"

chmod +x ./caddy

echo "Running custom Caddy build"

./caddy run --config /plugin-pipeline/managed-config.json

