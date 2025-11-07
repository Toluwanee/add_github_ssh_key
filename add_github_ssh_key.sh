#!/bin/bash

AUTHORIZED_KEYS=".ssh/authorized_keys"   # Relative path; resolved remotely
read -p "Enter path to host file(if host is in the same directory, just input its title): " HOST_FILE
read -p "Enter username of machine: " USER
read -p "Enter the full GitHub keys link: " GITHUB_KEYS_URL
read -p "Enter the user's mail: " NAME

# Validate host file
if [[ ! -f "$HOST_FILE" ]]; then
  echo "❌ Host file not found: $HOST_FILE"
  exit 1
fi

# Fetch keys from GitHub
KEYS=$(curl -s "$GITHUB_KEYS_URL")
if [ -z "$KEYS" ]; then
  echo "❌ No keys found at $GITHUB_KEYS_URL"
  exit 1
fi

# Loop through all hosts
while IFS= read -r HOST || [[ -n "$HOST" ]]; do
  [[ -z "$HOST" || "$HOST" == \#* ]] && continue

  echo "==== Connecting to $HOST ===="

  ssh -o BatchMode=yes -o ConnectTimeout=10 "$USER@$HOST" "bash -s" <<EOF
# Ensure .ssh directory and authorized_keys exist
mkdir -p ~/.ssh
touch ~/$AUTHORIZED_KEYS
chmod 700 ~/.ssh
chmod 600 ~/$AUTHORIZED_KEYS

# Check if the key already exists in authorized_keys
if grep -qF "$KEYS" ~/$AUTHORIZED_KEYS; then
  echo "⚠️  Key for $NAME already exists on $HOST"
else
  echo "$KEYS # Added for $NAME" >> ~/$AUTHORIZED_KEYS
  echo "✅ Key added for $NAME on $HOST"
fi

# Log entry
echo 'I entered this server with names and keys' > ~/entered.txt
EOF

  if [[ $? -eq 0 ]]; then
    echo "✅ Successfully processed $HOST"
  else
    echo "❌ Failed to connect or execute on $HOST"
  fi

  echo "==== Disconnected from $HOST ===="
  echo
done < "$HOST_FILE"

