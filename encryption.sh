
#!/bin/bash

set -euo pipefail

# auth helpers

generateSalt() {
    openssl rand -hex 16
}

hashMasterKey() {
    local masterKey="$1"
    local salt="$2"
    # Combines master key, base64 encoding, and a salt/timestamp
    printf "%s" "$(echo -n "$masterKey" | base64)$salt" | sha256sum | awk '{print $1}'
}

# encryption and decryption functions

encrypt(){
    local MASTER_KEY="$1"
    local password="$2"
    local TIMESTAMP
    TIMESTAMP=$(date +%s)

    # Use our helper function instead of rewriting the hash logic
    local KEY
    KEY="$(hashMasterKey "$MASTER_KEY" "$TIMESTAMP")"
    
    local IV
    IV="$(openssl rand -hex 16)"

    local ENCRYPTED_PASSWORD
    ENCRYPTED_PASSWORD="$(echo -n "$password" | openssl enc -aes-256-cbc -a -A -K "$KEY" -iv "$IV")"

    echo -n "$ENCRYPTED_PASSWORD|$IV|$TIMESTAMP"
}

decrypt(){
    local MASTER_KEY="$1"
    local ENCRYPTED_PASSWORD="$2"
    local IV="$3"
    local TIMESTAMP="$4"

    # Use the same helper function with the stored timestamp/salt
    local KEY
    KEY="$(hashMasterKey "$MASTER_KEY" "$TIMESTAMP")"

    local password
    password="$(echo -n "$ENCRYPTED_PASSWORD" | openssl enc -d -aes-256-cbc -a -A -K "$KEY" -iv "$IV")"

    echo -n "$password"
}
