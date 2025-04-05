#!/usr/bin/env sh
set -e
set -o errexit

RED="\\e[31m"
YELLOW="\\e[33m"
BLUE="\\e[34m"
WHITE="\\e[37m"
NC="\\e[0m"

STEP_NAME="$INPUT_STEP_NAME"
MACHINE="$INPUT_MACHINE"
DISTRO="$INPUT_DISTRO"
COMPOSE_FILE="$INPUT_COMPOSE_FILE"
NULIX_OS_VER="$INPUT_BASE_OS_VER"

LOG_ACT_ERR() {
  echo -e "${RED}[nulix/os-action]:${NC} ${@}"
}

LOG_ACT_WRN() {
  echo -e "${YELLOW}[nulix/os-action]:${NC} ${@}"
}

LOG_ACT_INF() {
  echo -e "${BLUE}[nulix/os-action]:${NC} ${@}"
}

LOG_ACT_DBG() {
  echo -e "${WHITE}[nulix/os-action]:${NC} ${@}"
}

fetch_base_os() {
  LOG_ACT_INF "Fetching base NULIX OS v$NULIX_OS_VER for $MACHINE"

  source /nulix-os-venv/bin/activate
  west init -m https://github.com/nulix/nulix-os.git nulix-os
  cd nulix-os
  west update

  MACHINE=$MACHINE DISTRO=$DISTRO source tools/setup-environment
  cd build/deploy/$MACHINE
  wget https://files.0xff.com.hr/$MACHINE/boot-artifacts-v2025.01.tar.gz
  wget https://files.0xff.com.hr/$MACHINE/kernel-artifacts-rpi-6.6.y.tar.gz
  wget https://files.0xff.com.hr/$MACHINE/$OSTREE_ROOTFS-$NULIX_OS_VER.tar.gz
  wget https://files.0xff.com.hr/$MACHINE/$OSTREE_REPO.tar.gz
  tar xzf $OSTREE_REPO.tar.gz
  mv -v $OSTREE_REPO ../../../rootfs
  mv -v $OSTREE_ROOTFS-*.tar.gz ../../../rootfs
  rm $OSTREE_REPO.tar.gz
  cd ../../..
  rm -f rootfs/$OSTREE_REPO.tar.gz
}

fetch_user_os() {
  LOG_ACT_INF "Fetching user NULIX OS"
}

inject_apps() {
  LOG_ACT_INF "Injecting custom compose apps into NULIX OS"

  mkdir rootfs/apps
  cp ../$COMPOSE_FILE rootfs/apps/docker-compose.yml

  nulix build ostree-repo
}

deploy_ota_update() {
  LOG_ACT_INF "Deploying OTA update"
  # TODO: implement this
}

build_os_image() {
  LOG_ACT_INF "Building NULIX OS v$NULIX_OS_VER image for $MACHINE"

  nulix build image
}

LOG_ACT_DBG
LOG_ACT_DBG "================================================"
LOG_ACT_DBG "============ Action Input Variables ============"
LOG_ACT_DBG "================================================"
LOG_ACT_DBG "STEP_NAME:    $STEP_NAME"
LOG_ACT_DBG "MACHINE:      $MACHINE"
LOG_ACT_DBG "DISTRO:       $DISTRO"
LOG_ACT_DBG "COMPOSE_FILE: $COMPOSE_FILE"
LOG_ACT_DBG "NULIX_OS_VER: $NULIX_OS_VER"
LOG_ACT_DBG "================================================"
LOG_ACT_DBG

echo "NULIX_OS_VER=${NULIX_OS_VER}" >> $GITHUB_ENV

case "$STEP_NAME" in
  build-os)
    LOG_ACT_INF "Building NULIX OS image"
    OSTREE_COMMIT_MSG="Added custom compose apps"
    fetch_base_os
    inject_apps
    deploy_ota_update
    build_os_image
    ;;
  update-apps)
    LOG_ACT_INF "Updating custom apps"
    OSTREE_COMMIT_MSG="Updated custom compose apps"
    fetch_user_os
    inject_apps
    deploy_ota_update
    ;;
  update-os)
    LOG_ACT_INF "Updating NULIX OS image"
    OSTREE_COMMIT_MSG="Added custom compose apps"
    fetch_base_os
    inject_apps
    deploy_ota_update
    ;;
  *)
    LOG_ACT_ERR "Unknown step: $STEP_NAME"
    return 1
    ;;
esac
