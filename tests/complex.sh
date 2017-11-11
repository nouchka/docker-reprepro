#!/bin/bash

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"
source functions

[ ! -d "${DATA_DIR}" ] || rm -rf "${DATA_DIR}"
mkdir -p "${DATA_DIR}"

docker run --name reprepro \
  --volume ${CONFIG_DIR}:/config:ro \
  --volume ${DATA_DIR}:/data \
  --env RPP_DISTRIBUTIONS="wdev;wprod;jdev;jprod" \
  --env RPP_CODENAME_wdev="wheezy-dev" \
  --env RPP_CODENAME_wprod="wheezy-prod" \
  --env RPP_CODENAME_jdev="jessie-dev" \
  --env RPP_CODENAME_jprod="jessie-prod" \
  --env RPP_ARCHITECTURES_wdev="amd64 armhf source" \
  --env RPP_ARCHITECTURES_wprod="amd64 armhf source" \
  --env RPP_ARCHITECTURES_jdev="amd64 armhf source" \
  --env RPP_ARCHITECTURES_jprod="amd64 armhf source" \
  --env RPP_INCOMINGS="in_wheezy;in_jessie" \
  --env RPP_ALLOW_in_wheezy="stable>wheezy-dev" \
  --env RPP_ALLOW_in_jessie="stable>jessie-dev" \
  --publish 22:22 \
  ${IMAGE_TAG}
