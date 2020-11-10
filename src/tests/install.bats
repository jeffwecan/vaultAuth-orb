#!/usr/bin/env bats

setup() {
    source src/scripts/install.sh
}

@test "extract latest version from releases site html" {
    input=$(cat src/tests/releases.html)
    run extract_latest_release "$input"
    [ $status -eq 0 ]
    [ $output == "1.5.5" ]
}
