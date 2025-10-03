#!/bin/bash

AUTHORIZED_KEYS="$HOME/.ssh/authorized_keys"

# Ensure ~/.ssh exists
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# Ensure authorized_keys file exists
touch "$AUTHORIZED_KEYS"
chmod 600 "$AUTHORIZED_KEYS"

# Ask for the GitHub .keys link
read -p "Enter the full GitHub .keys link (e.g., https://github.com/username.keys): " url

# Validate that input looks like a GitHub .keys link
if [[ ! "$url" =~ ^https://github.com/.+\.keys$ ]]; then
    echo "[ERROR] Invalid link. It must be in the form: https://github.com/<username>.keys"
    exit 1
fi

# Fetch keys
keys=$(curl -s "$url")

# Check if response is empty
if [[ -z "$keys" ]]; then
    echo "[ERROR] No keys found or link not reachable: $url"
    exit 1
fi

# Ask for the person's name/identifier
read -p "Enter the name/identifier for this user: " name

# Process each key
added=0
skipped=0
while IFS= read -r key; do
    if [[ -n "$key" ]]; then
        # Extract just the first 2 fields (key type + key data), ignore existing comments
        key_base=$(echo "$key" | awk '{print $1,$2}')

        # Check if the base key is already present in authorized_keys
        if grep -qF "$key_base" "$AUTHORIZED_KEYS"; then
            echo "[SKIP] Key already exists for $name"
            ((skipped++))
        else
            echo "$key # Added for $name" >> "$AUTHORIZED_KEYS"
            echo "[ADD] Key added for $name"
            ((added++))
        fi
    fi
done <<< "$keys"

echo "[DONE] $added new key(s) added, $skipped skipped ."
