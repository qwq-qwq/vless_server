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

# Detect transport type from config
detect_transport() {
    network=$(jq -r '.inbounds[0].streamSettings.network' "$CONFIG_FILE")
    security=$(jq -r '.inbounds[0].streamSettings.security' "$CONFIG_FILE")
    echo "${network}_${security}"
}

# Generate connection string based on transport type
generate_connection_string() {
    local uuid=$1
    local email=$2
    local domain=$3
    local port=$4
    local transport=$(detect_transport)

    case $transport in
        "tcp_reality")
            # Reality protocol
            local public_key=$(jq -r '.inbounds[0].streamSettings.realitySettings.publicKey // "NOT_SET"' "$CONFIG_FILE")
            local short_id=$(jq -r '.inbounds[0].streamSettings.realitySettings.shortIds[1] // ""' "$CONFIG_FILE")
            local server_name=$(jq -r '.inbounds[0].streamSettings.realitySettings.serverNames[0] // "microsoft.com"' "$CONFIG_FILE")
            local flow=$(jq -r '.inbounds[0].settings.clients[0].flow // "xtls-rprx-vision"' "$CONFIG_FILE")

            echo "vless://${uuid}@${domain}:${port}?security=reality&type=tcp&flow=${flow}&sni=${server_name}&fp=chrome&pbk=${public_key}&sid=${short_id}&encryption=none#${email}"
            ;;
        "ws_none"|"ws_tls")
            # WebSocket
            local ws_path=$(jq -r '.inbounds[0].streamSettings.wsSettings.path // "/vlessws"' "$CONFIG_FILE")
            local tls_enabled="tls"
            [[ "$transport" == "ws_none" ]] && tls_enabled="none" || tls_enabled="tls"

            if [[ "$tls_enabled" == "tls" ]]; then
                echo "vless://${uuid}@${domain}:${port}?security=tls&type=ws&path=${ws_path}&host=${domain}&encryption=none#${email}"
            else
                # WebSocket через Cloudflare (без TLS на сервере)
                echo "vless://${uuid}@${domain}:${port}?security=tls&type=ws&path=${ws_path}&host=${domain}&encryption=none#${email}"
            fi
            ;;
        "grpc_none"|"grpc_tls")
            # gRPC
            local service_name=$(jq -r '.inbounds[0].streamSettings.grpcSettings.serviceName // "GrpcService"' "$CONFIG_FILE")
            local multi_mode=$(jq -r '.inbounds[0].streamSettings.grpcSettings.multiMode // false' "$CONFIG_FILE")
            local mode="gun"
            [[ "$multi_mode" == "true" ]] && mode="multi" || mode="gun"

            echo "vless://${uuid}@${domain}:${port}?security=tls&type=grpc&serviceName=${service_name}&mode=${mode}&encryption=none#${email}"
            ;;
        *)
            # Fallback
            echo "vless://${uuid}@${domain}:${port}?encryption=none#${email}"
            ;;
    esac
}

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

    # Detect if Reality and add flow parameter
    transport=$(detect_transport)
    if [[ "$transport" == "tcp_reality" ]]; then
        flow=$(jq -r '.inbounds[0].settings.clients[0].flow // "xtls-rprx-vision"' "$CONFIG_FILE")
        jq --arg uuid "$new_uuid" --arg email "$email" --arg flow "$flow" \
            '.inbounds[0].settings.clients += [{"id": $uuid, "flow": $flow, "email": $email}]' \
            "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
    else
        jq --arg uuid "$new_uuid" --arg email "$email" \
            '.inbounds[0].settings.clients += [{"id": $uuid, "email": $email}]' \
            "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
    fi
    mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"

    # Get domain from docker-compose.yml
    domain=$(grep -o 'Host(`[^`]*`)' docker-compose.yml | head -1 | sed 's/Host(`\(.*\)`)/\1/')
    [[ -z "$domain" ]] && domain=$(grep -o 'HostSNI(`[^`]*`)' docker-compose.yml | head -1 | sed 's/HostSNI(`\(.*\)`)/\1/')
    [[ -z "$domain" ]] && domain="v-server.perek.rest"

    echo "User added successfully!"
    echo "======================="
    echo "Email: $email"
    echo "UUID: $new_uuid"
    echo "Domain: $domain"
    echo "Transport: $transport"
    echo "======================="
    echo
    echo "Connection strings for client:"
    echo

    # Show main connection string
    echo "📱 Main (Port 443):"
    generate_connection_string "$new_uuid" "$email" "$domain" "443"
    echo

    # If using WebSocket or gRPC (CDN compatible), show Cloudflare alternative ports
    if [[ "$transport" =~ ^(ws_|grpc_) ]]; then
        echo "🌐 Cloudflare alternative ports (if 443 is blocked):"
        for port in 2053 2083 2087 2096 8443; do
            echo
            echo "Port $port:"
            generate_connection_string "$new_uuid" "$email" "$domain" "$port"
        done
        echo
        echo "💡 Tip: Use Cloudflare CDN for best bypass in regions with heavy censorship"
        echo "    See BYPASS-GUIDE.md for detailed instructions"
    fi

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
    [[ -z "$domain" ]] && domain=$(grep -o 'HostSNI(`[^`]*`)' docker-compose.yml | head -1 | sed 's/HostSNI(`\(.*\)`)/\1/')
    [[ -z "$domain" ]] && domain="v-server.perek.rest"

    transport=$(detect_transport)
    echo "Transport type: $transport"
    echo "======================="
    echo

    # Get all users
    users=$(jq -c '.inbounds[0].settings.clients[]' "$CONFIG_FILE")

    if [ -z "$users" ]; then
        echo "No users found."
        return
    fi

    # Iterate through users
    echo "$users" | while IFS= read -r user; do
        email=$(echo "$user" | jq -r '.email')
        uuid=$(echo "$user" | jq -r '.id')

        echo "👤 User: $email"
        echo "   UUID: $uuid"
        echo
        echo "   📱 Main connection (Port 443):"
        echo "   $(generate_connection_string "$uuid" "$email" "$domain" "443")"
        echo

        # If using WebSocket or gRPC, show Cloudflare ports
        if [[ "$transport" =~ ^(ws_|grpc_) ]]; then
            echo "   🌐 Cloudflare alternative ports:"
            for port in 2053 2083 2087 2096 8443; do
                echo "   Port $port: $(generate_connection_string "$uuid" "$email" "$domain" "$port")"
            done
            echo
        fi

        echo "   ---------------------"
        echo
    done

    if [[ "$transport" =~ ^(ws_|grpc_) ]]; then
        echo "💡 For regions with heavy censorship (e.g., Lugansk region):"
        echo "   - Use Cloudflare CDN with alternative ports (2053, 2083, etc.)"
        echo "   - Enable client-side fragmentation (see BYPASS-GUIDE.md)"
        echo "   - Try gRPC transport for better obfuscation"
    fi
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