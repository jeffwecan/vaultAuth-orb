# Runs prior to every test
setup() {
    # Load our script file.
    source ./src/scripts/login.sh
}

@test '1: Authenticate to Vault' {
    # Mock environment variables or functions by exporting them (after the script has been sourced)
    export PARAM_VAULT_ADDR="http://localhost:8200"
    # Capture the output of our "Login" function
    result=$(Login)
    [ "$result" == "Hello World" ]
}
