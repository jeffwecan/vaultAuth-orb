#!/usr/bin/env bats

setup_file() {
    # ensure Vault is installed
    export PARAM_ARCH=amd64
    export PARAM_VERIFY=1
    sh src/scripts/install.sh

    export VAULT_TOKEN=1234567890
    export VAULT_ADDR=http://localhost:8200
    vault server -dev -dev-root-token-id=1234567890 &
    sleep 3
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
