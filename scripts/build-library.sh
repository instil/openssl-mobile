#!/bin/bash

set -e
cd "$(dirname "$0")"

PROFILE=$1
OUTPUT_LIB_DIR=../lib/$PROFILE
PROFILE_PARAMS="--profile ../../profiles/$PROFILE.profile"

if [[ -n "$2" ]]; then
  OUTPUT_LIB_DIR=../lib/$2
fi

if [[ "$PROFILE" == *"android"* ]]; then
  PROFILE_PARAMS="--profile:host ../../profiles/$PROFILE.profile --profile:build default"
fi

mkdir -p "$OUTPUT_LIB_DIR"
mkdir -p "build"

cd build
conan install ../.. $PROFILE_PARAMS --build=missing
cd ..

if [[ ! -d "../include" ]]; then
  INCLUDE_DIR=`grep -m1 'data/openssl/.*/include' build/conanbuildinfo.txt`
  cp -r $INCLUDE_DIR "../include"
fi

BUILT_LIB_DIR=`grep -m1 'data/openssl/.*/lib' build/conanbuildinfo.txt`
cp -r $BUILT_LIB_DIR/* "$OUTPUT_LIB_DIR"

rm -r build
