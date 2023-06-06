#!/usr/bin/env bats

setup() {
    export DID_RUN="$(mktemp -d)"
    export XDG_CONFIG_HOME=./data/autostart-folders/condition-home
    export XDG_CONFIG_DIRS=
}

teardown() {
    rm -r $DID_RUN
}

@test "Only starts applications with passing AutostartCondition" {
    run ../sway-launcher-desktop.sh autostart 3>&2
    echo -e "DID_RUN=$DID_RUN"
    [[ ! -e $DID_RUN/unless-exists.file-exists ]]
    [[ -e $DID_RUN/unless-exists.file-not-exists ]]
    [[ ! -e $DID_RUN/if-exists.file-not-exists ]]
    [[ -e $DID_RUN/if-exists.file-exists ]]
}
