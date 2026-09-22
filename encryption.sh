#!/bin/bash

encrypt(){
    local MASTER_KEY="$1"
    local password="$2"
    local TIMESTAMP=$(date +%s)

    local KEY="$(echo -n "$(echo -n "$MASTER_KEY" | base64)$TIMESTAMP" | sha256sum | awk '{print $1}')"
    
    local IV="$(openssl rand -hex 16)"

    local ENCRYPTED_PASSWORD="$(echo "$password" | openssl enc -aes-256-cbc -a -A -K "$KEY" -iv $IV)"

    echo -n "$ENCRYPTED_PASSWORD $IV $TIMESTAMP"
}

encrypt test test

decrypt(){
    local MASTER_KEY="$1"
    local ENCRYPTED_PASSWORD="$2"
    local TIMESTAMP="$3"
    local IV="$4"

    local KEY="$(echo -n "$(echo -n "$MASTER_KEY" | base64)$date" | sha256sum | awk '{print $1}')"

    local password="$(echo "$ENCRYPTED_PASSWORD" | openssl enc -d -aes-256-cbc -a -A -K "$KEY" -iv $IV)"

    echo -n "$password"
}
