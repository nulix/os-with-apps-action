#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

STEP="do_$1"

do_fetch-base-os() {
  source /nulix-os-venv/bin/activate
  west init -m https://github.com/nulix/nulix-os.git nulix-os
  cd nulix-os
  west update
  source tools/setup-environment
  cd build/deploy/$MACHINE
  wget https://files.0xff.com.hr/$MACHINE/$OSTREE_ROOTFS-$NULIX_OS_VER.tar.gz
  wget https://files.0xff.com.hr/$MACHINE/$OSTREE_REPO.tar.gz
  tar xzf $OSTREE_REPO.tar.gz
  mv -v $OSTREE_REPO ../../../rootfs
  mv -v $OSTREE_ROOTFS-*.tar.gz ../../../rootfs
  rm $OSTREE_REPO.tar.gz
  cd ../../..
  rm -f rootfs/$OSTREE_REPO.tar.gz
}

do_inject-apps() {
  cd nulix-os
  source tools/setup-environment
  OSTREE_COMMIT_MSG="Added custom compose apps"
  nulix build ostree-repo
}
