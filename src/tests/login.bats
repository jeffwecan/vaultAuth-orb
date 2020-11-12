#!/usr/bin/env bats


setup_file() {
    # ensure Vault is installed
    export PARAM_ARCH=amd64
    export PARAM_VERIFY=1
    sh src/scripts/install.sh

    export VAULT_TOKEN=1234567890
    export VAULT_ADDR=http://localhost:8200

    PLUGIN_DIR='/vault/plugins'
    mkdir --parents "$PLUGIN_DIR"
    wget https://github.com/jeffwecan/vault-circleci-auth-plugin/releases/download/0.2.0/vault-circleci-auth-plugin \
        -O "$PLUGIN_DIR/vault-circleci-auth-plugin"
    echo '{"plugin_directory": "'"$PLUGIN_DIR"'"}' > vault-test.json

    vault server -dev -dev-root-token-id=1234567890 -config=vault-test.json &

    circleci_auth_plugin_sha_256=$(sha256sum "$PLUGIN_DIR/vault-circleci-auth-plugin" | cut -d ' ' -f 1)
    /wait-for-it.sh -t 20 -h 127.0.0.1 -p 8200 -s -- vault write \
        sys/plugins/catalog/vault-circleci-auth \
        sha_256="$circleci_auth_plugin_sha_256" command=vault-circleci-auth-plugin
    vault auth \
        enable \
        -path=circleci \
        -plugin-name=vault-circleci-auth \
        plugin
    vault write auth/circleci/config \
        "circleci_token=$VAULT_CIRCLECI_TOKEN" \
        "vcs_type=github" \
        "owner=jeffwecan"

    vault auth enable userpass
    vault auth enable -path=altuser userpass
    vault auth enable approle
    vault write auth/userpass/users/testuser password=foo
    vault write auth/altuser/users/testuser password=foo
    vault token create -id=abcdefg -display-name=testtoken
    vault write -f auth/approle/role/testrole
    export PARAM_ROLEID=$(vault read -field=role_id auth/approle/role/testrole/role-id)
    export PARAM_SECRETID=$(vault write -f -field=secret_id auth/approle/role/testrole/secret-id)

    # remove root token
    export VAULT_TOKEN=
    rm ~/.vault-token
}

teardown_file() {
    kill -9 %1
}

setup() {
    source src/scripts/login.sh
}

teardown() {
    rm -f ~/.vault-token
}

@test "login with circleci-auth" {
    PARAM_METHOD=circleci
    run login_main "$PARAM_METHOD"
    [ $status -eq 0 ]
    user=$(vault read -format=json auth/token/lookup-self | jq -r '.data | .display_name')
    echo "stdout user: $user" 2>&1
    echo "stderr user: $user" 1>&2
    [ $user == "userpass-testuser" ]
}

@test "login with username and password" {
    PARAM_METHOD=userpass
    PARAM_USERNAME=testuser
    PARAM_PASSWORD=foo
    run login_main "$PARAM_METHOD"
    [ $status -eq 0 ]
    user=$(vault read -format=json auth/token/lookup-self | jq -r '.data | .display_name')
    [ $user == "userpass-testuser" ]
}

@test "login with username and password using non-default path" {
    PARAM_METHOD=userpass
    PARAM_USERNAME=testuser
    PARAM_PASSWORD=foo
    PARAM_PATH=altuser
    run login_main "$PARAM_METHOD"
    [ $status -eq 0 ]
    user=$(vault read -format=json auth/token/lookup-self | jq -r '.data | .display_name')
    [ $user == "altuser-testuser" ]
}

@test "login with token" {
    PARAM_METHOD=token
    PARAM_TOKEN=abcdefg
    run login_main "$PARAM_METHOD"
    [ $status -eq 0 ]
    user=$(vault read -format=json auth/token/lookup-self | jq -r '.data | .display_name')
    echo $user
    [ $user == "token-testtoken" ]
}

@test "login with approle" {
    PARAM_METHOD=approle
    run login_main "$PARAM_METHOD"
    [ $status -eq 0 ]
    role=$(vault read -format=json auth/token/lookup-self | jq -r '.data | .meta | .role_name')
    [ $role == "testrole" ]
}
