#!/bin/sh

login_circleci() {
    path="$1"
    vault write "auth/$path/login"  \
        project="$CIRCLE_PROJECT_REPONAME" \
        build_num="$CIRCLE_BUILD_NUM" \
        vcs_revision="$CIRCLE_SHA1" \
    | grep token | awk '{print $2}' | head -n 1 > ~/.vault-token
}

login_userpass() {
    username=$1
    password=$2
    path=$3
    vault login -no-print -method=userpass -path="$path" username="$username" password="$password"
}

login_token() {
    token=$1
    vault login -no-print -method=token -path="$path" token="$token"
}

login_approle() {
    role_id=$1
    secret_id=$2
    path=$3
    vault write "auth/$path/login" role_id="$role_id" secret_id="$secret_id" | grep token | awk '{print $2}' | head -n 1 > ~/.vault-token
}

login_main() {
    METHOD=$1
    AUTH_PATH="$PARAM_PATH"

    if [ "$AUTH_PATH" = "" ]; then
        AUTH_PATH=$METHOD
    fi

    case "$METHOD" in

    circleci)
      login_circleci "$AUTH_PATH"
      ;;

    userpass)
      login_userpass "$PARAM_USERNAME" "$PARAM_PASSWORD" "$AUTH_PATH"
      ;;

    token)
      login_token "$PARAM_TOKEN" "$AUTH_PATH"
      ;;

    approle)
      login_approle "$PARAM_ROLEID" "$PARAM_SECRETID" "$AUTH_PATH"
      ;;

    *)
      echo "Unsupported login method"
      exit 1
      ;;
    esac
}

ORB_TEST_ENV="bats-core"
if [ "${0#*$ORB_TEST_ENV}" = "$0" ]; then
    login_main "$PARAM_METHOD"
fi
