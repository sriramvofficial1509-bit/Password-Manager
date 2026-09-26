#!/usr/bin/env bash

set -euo pipefail

DB_FILE="vault.db"

escape() {
    printf '%s' "${1//\'/\'\'}"
}

init_db() {
    sqlite3 "$DB_FILE" <<'EOF'
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS users (
    username TEXT PRIMARY KEY,
    salt TEXT NOT NULL,
    authHash TEXT NOT NULL,
    epoch INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS passwords (
    username TEXT NOT NULL,
    domain TEXT NOT NULL,
    encryptedPassword TEXT NOT NULL,
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
    local username="${1:?Username required}"
    local salt="${2:?Salt required}"
    local authHash="${3:?AuthHash required}"
    local epoch="${4:-$(date +%s)}"

    sqlite3 "$DB_FILE" \
        -cmd "PRAGMA foreign_keys = ON;" \
        -cmd ".parameter init" \
        -cmd ".parameter set :u '$(escape "$username")'" \
        -cmd ".parameter set :s '$(escape "$salt")'" \
        -cmd ".parameter set :h '$(escape "$authHash")'" \
        -cmd ".parameter set :e $epoch" \
        "INSERT INTO users (username, salt, authHash, epoch) VALUES (:u, :s, :h, :e);"
}

getUser() {
    local username="${1:?Username required}"
    local result

    result=$(sqlite3 "$DB_FILE" \
        -cmd ".parameter init" \
        -cmd ".parameter set :u '$(escape "$username")'" \
        "SELECT salt, authHash FROM users WHERE username = :u;")

    if [[ -z "$result" ]]; then
        return 1
    fi 

    echo "$result"
}

# password functions

addPassword() {
    local username="${1:?Username required}"
    local domain="${2:?Domain required}"
    local encPass="${3:?Encrypted password required}"
    local iv="${4:?IV required}"
    local epoch="${5:-$(date +%s)}"

    sqlite3 "$DB_FILE" \
        -cmd "PRAGMA foreign_keys = ON;" \
        -cmd ".parameter init" \
        -cmd ".parameter set :u '$(escape "$username")'" \
        -cmd ".parameter set :d '$(escape "$domain")'" \
        -cmd ".parameter set :p '$(escape "$encPass")'" \
        -cmd ".parameter set :iv '$(escape "$iv")'" \
        -cmd ".parameter set :e $epoch" \
        "INSERT INTO passwords (username, domain, encryptedPassword, iv, epoch)
         VALUES (:u, :d, :p, :iv, :e)
         ON CONFLICT(username, domain) DO UPDATE SET
             encryptedPassword = excluded.encryptedPassword,
             iv = excluded.iv,
             epoch = excluded.epoch;"
}

getPassword() {
    local username="${1:?Username required}"
    local domain="${2:?Domain required}"
    local result

    result=$(sqlite3 "$DB_FILE" \
        -cmd ".parameter init" \
        -cmd ".parameter set :u '$(escape "$username")'" \
        -cmd ".parameter set :d '$(escape "$domain")'" \
        "SELECT encryptedPassword, iv, epoch FROM passwords WHERE username = :u AND domain = :d;")

    if [[ -z "$result" ]]; then
        return 1
    fi 

    echo "$result"
}

listDomains() {
    local username="${1:?Username required}"

    sqlite3 "$DB_FILE" \
        -cmd ".parameter init" \
        -cmd ".parameter set :u '$(escape "$username")'" \
        "SELECT domain FROM passwords WHERE username = :u ORDER BY domain ASC;"
}

# cli entry

cmd="${1:-}"
shift || true

case "$cmd" in
    init)
        init_db
        ;;
    add-user)
        # Usage: ./db.sh add-user <username> <salt> <authHash> [epoch]
        addUser "$1" "$2" "$3" "${4:-}"
        ;;
    get-user)
        # Usage: ./db.sh get-user <username>
        getUser "$1"
        ;;
    add-pass)
        # Usage: ./db.sh add-pass <username> <domain> <encPass> <iv> [epoch]
        addPassword "$1" "$2" "$3" "$4" "${5:-}"
        ;;
    get-pass)
        # Usage: ./db.sh get-pass <username> <domain>
        getPassword "$1" "$2"
        ;;
    list-domains)
        # Usage: ./db.sh list-domains <username>
        listDomains "$1"
        ;;
    *)
        echo "Usage: $0 {init|add-user|get-user|add-pass|get-pass|list-domains}" >&2
        exit 1
        ;;
esac
