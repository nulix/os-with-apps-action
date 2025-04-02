#!/usr/bin/env sh

set -o errexit
set -o pipefail

STEP_NAME=$(echo "$INPUT_STEP_NAME" | tr '-' '_')
MACHINE="$INPUT_MACHINE"
DISTRO="$INPUT_DISTRO"
COMPOSE_FILE="$INPUT_COMPOSE_FILE"
NULIX_OS_VER="1.3.1"

echo "================================================"
echo "============ Action Input Variables ============"
echo "================================================"
echo "STEP:             $STEP_NAME"
echo "MACHINE:          $MACHINE"
echo "DISTRO:           $DISTRO"
echo "COMPOSE FILE:     $COMPOSE_FILE"
echo "NULIX OS version: $NULIX_OS_VER"
echo "================================================"

do_fetch_base_os() {
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

do_inject_apps() {
  cd nulix-os
  cp ../$COMPOSE_FILE rootfs/apps
  echo '------------------' && ls -lh rootfs && ls -lh rootfs/apps && cat rootfs/apps/$COMPOSE_FILE && echo '------------------'
  MACHINE=$MACHINE DISTRO=$DISTRO source tools/setup-environment
  OSTREE_COMMIT_MSG="Added custom compose apps"
  nulix build ostree-repo
}

do_build_os_image() {
  cd nulix-os
  MACHINE=$MACHINE DISTRO=$DISTRO source tools/setup-environment
  cd build/deploy/$MACHINE
  wget https://files.0xff.com.hr/$MACHINE/boot-artifacts-v2025.01.tar.gz
  wget https://files.0xff.com.hr/$MACHINE/kernel-artifacts-rpi-6.6.y.tar.gz
  cd ../../..
  nulix build image
}

do_$STEP_NAME
