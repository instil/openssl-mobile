#!/bin/bash

# Simple script to build OpenSSL for iOS (an eventually Android, or optionally pull the binaries for the latest release from GitHub.

REPO_ID="Pkshields/openssl-mobile"
TEMP_OUTPUT_DIR="/tmp/openssl-mobile"
TEMP_ZIP_FILE="binary.zip"

getLatestReleaseDownloadUrl() {
  curl --silent "https://api.github.com/repos/${REPO_ID}/releases/latest" |
    grep '"browser_download_url":' |
    sed -E 's/.*"([^"]+)".*/\1/'
}

if [[ $* == *--no-build* ]]; then
	echo "Downloading latest OpenSSL release"

	DOWNLOAD_URL=`getLatestReleaseDownloadUrl`

	rm -rf ${TEMP_OUTPUT_DIR} > /dev/null
	rm -rf include/* > /dev/null
	rm -rf lib/* > /dev/null

	mkdir -p "${TEMP_OUTPUT_DIR}"
	wget "${DOWNLOAD_URL}" -O "${TEMP_OUTPUT_DIR}/${TEMP_ZIP_FILE}"
	unzip "${TEMP_OUTPUT_DIR}/${TEMP_ZIP_FILE}" -d .

	echo "Completed"
else
	./build-ios-mac.sh
	./build-android.sh
fi
