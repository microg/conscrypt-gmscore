#!/bin/bash
# SPDX-FileCopyrightText: 2020, microG Project Team
# SPDX-License-Identifier: Apache-2.0

CONSCRYPT_REVISION=2.5.2
BORINGSSL_REVISION=409ea2837deef434be575d6e790ecc93df9dc899

ROOT=$PWD
ANDROID_HOME=${ANDROID_HOME:-$ANDROID_SDK_ROOT}
if [ "$ANDROID_HOME" = "" ]; then echo "Set ANDROID_HOME or ANDROID_SDK_ROOT to point to Android SDK."; exit; fi

checkout() {
  NAME=$1
  URL=$2
  FETCH=$3
  CHECKOUT=${4:-$FETCH}
  GIT_DIR=$(readlink -f $NAME.git)
  WT_DIR=$(readlink -f $NAME)
  GIT_ARGS="--work-tree $WT_DIR --git-dir $GIT_DIR"

  if ! [ -d $GIT_DIR ]; then
    echo "Cloning $NAME from $URL"
    git $GIT_ARGS clone -q -b $FETCH --bare $URL $GIT_DIR
  else
    echo "Fetching $NAME from $URL"
    git $GIT_ARGS fetch -q -t $URL $FETCH
  fi
  if [ -d $WT_DIR ]; then rm -rf $WT_DIR; fi
  mkdir $WT_DIR
  echo "Setting $NAME to $CHECKOUT"
  git $GIT_ARGS checkout -q --detach $CHECKOUT
  git $GIT_ARGS checkout -q $CHECKOUT -- .
}

echo "## Preparing boringssl..."
checkout boringssl https://boringssl.googlesource.com/boringssl master $BORINGSSL_REVISION
mkdir -p $ROOT/boringssl/build64

echo "## Preparing conscrypt..."
checkout conscrypt https://github.com/google/conscrypt $CONSCRYPT_REVISION
patch -p1 -d $(readlink -f conscrypt) < $PWD/files/conscrypt-gmscore.patch

echo "## Building conscrypt..."
cd $ROOT/conscrypt
ANDROID_SDK_ROOT=$ANDROID_HOME ANDROID_HOME=$ANDROID_HOME BORINGSSL_HOME=$ROOT/boringssl ./gradlew :conscrypt-gmscore:build
