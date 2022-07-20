#!/bin/bash

REPO_ID="instil/openssl-mobile"

getReleaseDownloadUrl() {
  RELEASE="latest"
  if [ -n "$1" ]; then
    RELEASE="tags/$1"
  fi

  if [ -n "$TOKEN" ]
  then
    curl --silent --header "authorization: Bearer $TOKEN" "https://api.github.com/repos/$REPO_ID/releases/$RELEASE" |
        grep '"browser_download_url":' |
        sed -E 's/.*"([^"]+)".*/\1/'
  else
    curl --silent "https://api.github.com/repos/$REPO_ID/releases/$RELEASE" |
        grep '"browser_download_url":' |
        sed -E 's/.*"([^"]+)".*/\1/'
  fi
}

TOKEN=$1
GIT_TAG=$(git describe --tags --exact-match)
if [ $? != 0 ]; then
  GIT_TAG=""
fi

set -e

cd "$(dirname "$0")"

DOWNLOAD_URL=`getReleaseDownloadUrl $GIT_TAG`

rm -rf include/*
rm -rf lib/*

wget --silent "${DOWNLOAD_URL}" -O "/tmp/release.zip"
unzip "/tmp/release.zip" -d .

