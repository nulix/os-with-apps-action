#!/usr/bin/env sh

set -o errexit
set -o nounset
set -o pipefail

STEP_NAME="$INPUT_STEP_NAME"
MACHINE="$INPUT_MACHINE"
DISTRO="$INPUT_DISTRO"

echo "================================================="
echo "================ Input variables ================"
echo "================================================="
echo "Running step: $STEP_NAME"
echo "Machine: $MACHINE"
echo "Distro: $DISTRO"
echo "================================================="

do_fetch-base-os() {
  source /nulix-os-venv/bin/activate
  west init -m https://github.com/nulix/nulix-os.git nulix-os
  cd nulix-os
  west update
  MACHINE=$MACHINE DISTRO=$DISTRO source tools/setup-environment
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
  MACHINE=$MACHINE DISTRO=$DISTRO source tools/setup-environment
  OSTREE_COMMIT_MSG="Added custom compose apps"
  nulix build ostree-repo
}

do_$STEP_NAME
