#!/bin/bash

# Script for managing VLESS users
# Usage: ./manage-users.sh [add|remove|list] [email]

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq is required but not installed. Please install it with:"
    echo "apt-get install jq (Debian/Ubuntu) or yum install jq (CentOS/RHEL)"
    exit 1
fi

CONFIG_FILE="config/config.json"

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Config file $CONFIG_FILE not found!"
    exit 1
fi

# Function to add a new user
add_user() {
    email=$1
    
    if [ -z "$email" ]; then
        echo "Please provide an email for the new user"
        echo "Usage: $0 add client@example.com"
        exit 1
    fi
    
    # Check if user already exists
    if jq -e --arg email "$email" '.inbounds[0].settings.clients[] | select(.email == $email)' "$CONFIG_FILE" > /dev/null; then
        echo "User with email $email already exists!"
        exit 1
    fi
    
    # Generate UUID
    new_uuid=$(uuidgen)
    
    # Add user to config
    jq --arg uuid "$new_uuid" --arg email "$email" '.inbounds[0].settings.clients += [{"id": $uuid, "level": 0, "email": $email}]' "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
    mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    
    # Get domain from docker-compose.yml
    domain=$(grep -o 'Host(`[^`]*`)' docker-compose.yml | head -1 | sed 's/Host(`\(.*\)`)/\1/')
    
    echo "User added successfully!"
    echo "======================="
    echo "Email: $email"
    echo "UUID: $new_uuid"
    echo "Domain: $domain"
    echo "======================="
    echo "Connection string for client:"
    echo "vless://$new_uuid@$domain:443?security=tls&type=tcp&encryption=none#$email"
    echo
    echo "Restarting the server to apply changes..."
    docker-compose restart
}

# Function to remove a user
remove_user() {
    email=$1
    
    if [ -z "$email" ]; then
        echo "Please provide the email of the user to remove"
        echo "Usage: $0 remove client@example.com"
        exit 1
    fi
    
    # Check if user exists
    if ! jq -e --arg email "$email" '.inbounds[0].settings.clients[] | select(.email == $email)' "$CONFIG_FILE" > /dev/null; then
        echo "User with email $email not found!"
        exit 1
    fi
    
    # Remove user from config
    jq --arg email "$email" '.inbounds[0].settings.clients = [.inbounds[0].settings.clients[] | select(.email != $email)]' "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
    mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    
    echo "User $email removed successfully!"
    echo "Restarting the server to apply changes..."
    docker-compose restart
}

# Function to list all users
list_users() {
    echo "Current VLESS users:"
    echo "======================="
    
    # Get domain from docker-compose.yml
    domain=$(grep -o 'Host(`[^`]*`)' docker-compose.yml | head -1 | sed 's/Host(`\(.*\)`)/\1/')
    
    # List users with connection strings
    jq -r '.inbounds[0].settings.clients[] | "Email: \(.email)\nUUID: \(.id)\nConnection string: vless://\(.id)@'$domain':443?security=tls&type=tcp&encryption=none#\(.email)\n---------------------"' "$CONFIG_FILE"
}

# Main script
case "$1" in
    add)
        add_user "$2"
        ;;
    remove)
        remove_user "$2"
        ;;
    list)
        list_users
        ;;
    *)
        echo "Usage: $0 [add|remove|list] [email]"
        echo "Examples:"
        echo "  $0 add client@example.com - Add a new user"
        echo "  $0 remove client@example.com - Remove a user"
        echo "  $0 list - List all users"
        exit 1
        ;;
esac