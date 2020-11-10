#!/bin/sh

extract_latest_release() {
    raw_html=$1
    echo "$raw_html" | awk -F_ '$0 ~ /vault_[0-9]\.[0-9]\.[0-9]</ {gsub(/<\/a>/, ""); print $2}' | head -n 1
}

get_latest_release() {
    raw_html=$(curl -Ls --fail --retry 3 https://releases.hashicorp.com/vault/)
    extract_latest_release "$raw_html"
}

verify_vault() {
    VERSION=$1
    ARCH=$2
    PLATFORM=$3
    curl -s "https://keybase.io/_/api/1.0/key/fetch.json?pgp_key_ids=51852D87348FFC4C" | jq -r '.keys | .[0] | .bundle' > hashicorp.asc
    gpg --import hashicorp.asc
    curl -Os "https://releases.hashicorp.com/vault/$VERSION/vault_${VERSION}_SHA256SUMS"
    curl -Os "https://releases.hashicorp.com/vault/$VERSION/vault_${VERSION}_SHA256SUMS.sig"
    gpg --verify "vault_${VERSION}_SHA256SUMS.sig" "vault_${VERSION}_SHA256SUMS"
    grep "${PLATFORM}_${ARCH}.zip" "vault_${VERSION}_SHA256SUMS" | shasum -a 256 -
    echo "Verified Vault binary"
    rm "vault_${VERSION}_SHA256SUMS.sig" "vault_${VERSION}_SHA256SUMS" hashicorp.asc
}

install_vault() {
    VERSION=$1
    ARCH=$2
    VERIFY=$3
    if which vault > /dev/null; then
      echo "Vault is already installed"
      exit 0
    fi
    PLATFORM="linux"
    if uname | grep "Darwin"
    then
      PLATFORM="darwin"
    fi
    if [ -z "$VERSION" ]; then
      VERSION=$(get_latest_release)
    fi
    FILENAME="vault_${VERSION}_${PLATFORM}_${ARCH}.zip"
    DOWNLOAD_URL="https://releases.hashicorp.com/vault/$VERSION/$FILENAME"

    curl -L --fail --retry 3 -o "$FILENAME" "$DOWNLOAD_URL"
    if [ "$VERIFY" -eq 1 ]; then
      verify_vault "$VERSION" "$ARCH" "$PLATFORM"
    fi
    unzip "$FILENAME"
    rm "$FILENAME"
    SUDO=""
    if [ "$(id -u)" -ne 0 ] && which sudo > /dev/null ; then
      SUDO="sudo"
    fi
    $SUDO mv ./vault /usr/local/bin/vault
    vault version
}

ORB_TEST_ENV="bats-core"
if [ "${0#*$ORB_TEST_ENV}" = "$0" ]; then
    install_vault "$PARAM_VERSION" "$PARAM_ARCH" "$PARAM_VERIFY"
fi
