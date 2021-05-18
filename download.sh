#!/bin/bash

REPO_ID="instil/openssl-mobile"

getReleaseDownloadUrl() {
  RELEASE="latest"
  if [ -n "$1" ]; then
    RELEASE="tags/$1"
  fi

  echo "https://api.github.com/repos/$REPO_ID/releases/$RELEASE"

  curl --silent "https://api.github.com/repos/$REPO_ID/releases/$RELEASE" |
    grep '"browser_download_url":' |
    sed -E 's/.*"([^"]+)".*/\1/'
}

GIT_TAG=$(git describe --tags --exact-match)
if [ $? != 0 ]; then
  GIT_TAG=""
fi

set -e

cd "$(dirname "$0")"

DOWNLOAD_URL=`getReleaseDownloadUrl $GIT_TAG`

rm -rf include/*
rm -rf lib/*

wget "${DOWNLOAD_URL}" -O "/tmp/release.zip"
unzip "/tmp/release.zip" -d .
