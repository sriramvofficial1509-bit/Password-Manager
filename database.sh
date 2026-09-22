#!/usr/bin/env bash

set -euo pipefail

DB_FILE="vault.db"

init_db() {
    sqlite3 "$DB_FILE" <<'EOF'
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS users (
    username TEXT PRIMARY KEY,
    salt TEXT NOT NULL,
    auth_hash TEXT NOT NULL,
    epoch INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS passwords (
    username TEXT NOT NULL,
    domain TEXT NOT NULL,
    encrypted_password TEXT NOT NULL,
    iv TEXT NOT NULL,
    epoch INTEGER NOT NULL,
    PRIMARY KEY (username, domain),
    FOREIGN KEY (username) REFERENCES users(username) ON DELETE CASCADE
);
EOF
    chmod 600 "$DB_FILE"
}

# user functions

addUser() {
    local username="$1"
    local salt="$2"
    local authHash="$3"
    local epoch="${4:-$(date +%s)}"

    sqlite3 "$DB_FILE" \
        -param :u "$username" \
        -param :s "$salt" \
        -param :h "$authHash" \
        -param :e "$epoch" \
        "INSERT INTO users (username, salt, authHash, epoch) VALUES (:u, :s, :h, :e);"
}

getUser() {
    local username="$1"

    local result
    
    result=$(sqlite3 "$DB_FILE" \
        -param :u "$username" \
        "SELECT salt, authHash FROM users WHERE username = :u;")

    if [[ -z "$result" ]]; then
        return 1
    fi 

    echo "$result"
}
