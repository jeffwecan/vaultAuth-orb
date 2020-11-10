# ensure_vault_cli_installed() {
#     VAULT_URL="https://releases.hashicorp.com/vault"
#     curl \
#         --silent \
#         --remote-name \
#         "${VAULT_URL}/${PARAM_VAULT_VERSION}/vault_${PARAM_VAULT_VERSION}_linux_amd64.zip"
#     curl \
#         --silent \
#         --remote-name \
#         "${VAULT_URL}/vault/${PARAM_VAULT_VERSION}/vault_${PARAM_VAULT_VERSION}_SHA256SUMS"
#     curl \
#         --silent \
#         --remote-name \
#         "${VAULT_URL}/${PARAM_VAULT_VERSION}/${PARAM_VAULT_VERSION}/vault_${PARAM_VAULT_VERSION}_SHA256SUMS.sig"

#     gpg --keyserver keyserver.ubuntu.com --recv-keys 51852D87348FFC4C
#     gpg --verify vault_1.5.3_SHA256SUMS.sig vault_1.5.3_SHA256SUMS

# }

Login() {
    ensure_vault_cli_installed
    vault write -address="$PARAM_VAULT_ADDR"\
        "auth/$PARAM_AUTH_PATH/login" \
        project="$CIRCLE_PROJECT_REPONAME" \
        build_num="$CIRCLE_BUILD_NUM" \
        vcs_revision="$CIRCLE_SHA1"
    echo Hello "${PARAM_TO}"
}

# Will not run if sourced for bats-core tests.
# View src/tests for more information.
ORB_TEST_ENV="bats-core"
if [ "${0#*$ORB_TEST_ENV}" == "$0" ]; then
    Login
fi
