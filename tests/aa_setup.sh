#!/bin/bash

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"
source functions

[ ! -d "${CONFIG_DIR}" ] || rm -rf "${CONFIG_DIR}"
mkdir -p ${CONFIG_DIR}

gpg --batch --passphrase reprepro --quick-generate-key reprepro rsa4096


