#!/usr/bin/env bash

ROOT=$(pwd)
DIR=$1
FRONT_END=${2:-"react"}

echo ">> Creating directory $DIR"

mkdir -p $DIR
cd $DIR

if [ -z "$(asdf --version 2> /dev/null)" ]; then
    echo ">> This script requires ASDF"
    exit 1
fi

echo "nodejs 16.15.0
firebase 11.0.1
jq 1.6
gcloud 386.0.0" > .tool-versions

echo ">> Adding asdf plugins" 
asdf plugin add nodejs
asdf plugin add firebase
asdf plugin add gcloud
asdf plugin add jq

asdf install

echo ">> Creating turbo-repo"
npx create-turbo@latest --use-npm --no-install .

echo ">> Cleaning lint rules and readme"
rm -rf .eslintrc.js README.md package-lock.json

echo ">> Cleaning up apps/*"
rm -rf ./apps/*

echo ">> Creating a $FRONT_END project with vite"
if [ "$FRONT_END" = 'solidjs' ]; then
    npx degit solidjs/templates/ts apps/web
else
    npm create vite@latest -- --template react-ts web
    mv web apps/web
fi

echo ">> Cleaning up $FRONT_END files"
rm -rf apps/web/README.md apps/web/*-lock.*

echo ">> Cleaning up packages/*"
rm -rf packages/*

echo ">> Creating common and libs"
mkdir -p packages/libs && echo '{
  "name": "libs",
  "main": "index.ts",
  "types": "index.ts"
}' > packages/libs/package.json

echo "export const libs = \"libs\";" > packages/libs/index.ts

echo ">> Creating common config"
mkdir -p packages/config && echo '{
  "name": "config",
  "main": "index.ts",
  "types": "index.ts"
}' > packages/config/package.json

echo "export const config = \"config\";" > packages/config/index.ts

echo ">> Setup functions
Manually run:
  $ cd $DIR; firebase init functions

Selecting:
- [yes] typescript
- [yes] eslint
- [no] install dependencies
"

read -p ">> Waiting for functions install. Press enter here when complete." < /dev/tty

mv functions apps/functions

jq '.functions += {"source": "apps/functions"}' firebase.json > /tmp/firebase.json
mv /tmp/firebase.json firebase.json

echo ">> Setup firestore
Manually run:
  $ cd $DIR; firebase init firestore

Selecting:
- [yes] defaults
"

read -p ">> Waiting for firestore install. Press enter here when complete." < /dev/tty

echo ">> Setup storage
Manually run:
  $ cd $DIR; firebase init storage

Selecting:
- [yes] defaults
"

read -p ">> Waiting for storage install. Press enter here when complete." < /dev/tty

echo ">> Setup hosting
Manually run:
  $ cd $DIR; firebase init hosting

Selecting:
- [Public directory] apps/web/dist
- [yes] Configure as a single-page app
- [no] Set up automatic builds and deploys with GitHub
"

read -p ">> Waiting for hosting install. Press enter here when complete." < /dev/tty

npm install