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
STATIC_CONTENT_provider=$(jq -r .STATIC_CONTENT.provider caddy-build.json)
STATIC_CONTENT_url=$(jq -r .STATIC_CONTENT.url caddy-build.json)
STATIC_CONTENT_repo=$(jq -r .STATIC_CONTENT.repo caddy-build.json)
STATIC_CONTENT_owner=$(jq -r .STATIC_CONTENT.owner caddy-build.json)
STATIC_CONTENT_branch=$(jq -r .STATIC_CONTENT.branch caddy-build.json)
STATIC_CONTENT_path=$(jq -r .STATIC_CONTENT.path caddy-build.json)

GOPRIVATE=github.com/$ACCESS_TOKEN_USR/*

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

# echo the static content values
echo "STATIC_CONTENT_provider: $STATIC_CONTENT_provider"
echo "STATIC_CONTENT_url: $STATIC_CONTENT_url"
echo "STATIC_CONTENT_repo: $STATIC_CONTENT_repo"
echo "STATIC_CONTENT_owner: $STATIC_CONTENT_owner"
echo "STATIC_CONTENT_branch: $STATIC_CONTENT_branch"
echo "STATIC_CONTENT_path: $STATIC_CONTENT_path"

if [ "$STATIC_CONTENT_provider" == "github" ]; then
  echo "Cloning static content repo from github"
  GIT_URL=$( [[ -n "$ACCESS_TOKEN_PWD" ]] && echo "https://oauth2:${ACCESS_TOKEN_PWD}@github.com/${STATIC_CONTENT_owner}/${STATIC_CONTENT_repo}.git" || echo "https://github.com/${STATIC_CONTENT_owner}/${STATIC_CONTENT_repo}.git" )
  git clone $GIT_URL /static --single-branch --depth 1 --branch "$STATIC_CONTENT_branch" &
fi

wait

echo "Building Caddy with xCaddy"

BUILD_COMMAND="xcaddy build \
  $MODULE_FLAGS \
  --with github.com/appmasker/caddy-admin-repeat=./caddy-admin-repeat \
  --with github.com/appmasker/caddy_rest_storage=./caddy_rest_storage"

echo "FINAL COMMAND: $BUILD_COMMAND"

eval "$BUILD_COMMAND"

chmod +x ./caddy

echo "Running custom Caddy build"

./caddy run --config /plugin-pipeline/managed-config.json

