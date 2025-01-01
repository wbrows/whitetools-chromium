#!/bin/bash

if [[ -z "${INDEX_VERSION}" ]]; then
   echo "Please set INDEX_VERSION env variable"
   exit 1
fi

FLD=/storage/images/$INDEX_VERSION/android/true/arm64

cp $FLD/cromite.idx .
cp $FLD/RELEASE .

DOCKER_BUILDKIT=1 docker build -t uazo/bromite-remote-index:$INDEX_VERSION \
                --progress plain \
                --no-cache \
                .
