#!/bin/bash

set -euo pipefail

# auth helpers

generateSalt() {
    openssl rand -hex 16
}

hashMasterKey() {
    local masterKey="$1"
    local salt="$2"
    printf "%s%s" "$masterKey" "$salt" | sha256sum | awk '{print $1}'
}

# encryption and decryption functions

encrypt(){
    local MASTER_KEY="$1"
    local password="$2"
    local TIMESTAMP=$(date +%s)

    local KEY="$(echo -n "$(echo -n "$MASTER_KEY" | base64)$TIMESTAMP" | sha256sum | awk '{print $1}')"
    
    local IV="$(openssl rand -hex 16)"

    local ENCRYPTED_PASSWORD="$(echo -n "$password" | openssl enc -aes-256-cbc -a -A -K "$KEY" -iv $IV)"

    echo -n "$ENCRYPTED_PASSWORD|$IV|$TIMESTAMP"
}

decrypt(){
    local MASTER_KEY="$1"
    local ENCRYPTED_PASSWORD="$2"
    local IV="$3"
    local TIMESTAMP="$4"

    local KEY="$(echo -n "$(echo -n "$MASTER_KEY" | base64)$TIMESTAMP" | sha256sum | awk '{print $1}')"

    local password="$(echo -n "$ENCRYPTED_PASSWORD" | openssl enc -d -aes-256-cbc -a -A -K "$KEY" -iv $IV)"

    echo -n "$password"
}
