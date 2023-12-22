#!/bin/bash

" Author: mkdemir
" Date: 2023-12-22

" ███▄ ▄███▓ ██ ▄█▀▓█████▄ ▓█████  ███▄ ▄███▓ ██▓ ██▀███  
"▓██▒▀█▀ ██▒ ██▄█▒ ▒██▀ ██▌▓█   ▀ ▓██▒▀█▀ ██▒▓██▒▓██ ▒ ██▒
"▓██    ▓██░▓███▄░ ░██   █▌▒███   ▓██    ▓██░▒██▒▓██ ░▄█ ▒
"▒██    ▒██ ▓██ █▄ ░▓█▄   ▌▒▓█  ▄ ▒██    ▒██ ░██░▒██▀▀█▄  
"▒██▒   ░██▒▒██▒ █▄░▒████▓ ░▒████▒▒██▒   ░██▒░██░░██▓ ▒██▒
"░ ▒░   ░  ░▒ ▒▒ ▓▒ ▒▒▓  ▒ ░░ ▒░ ░░ ▒░   ░  ░░▓  ░ ▒▓ ░▒▓░
"░  ░      ░░ ░▒ ▒░ ░ ▒  ▒  ░ ░  ░░  ░      ░ ▒ ░  ░▒ ░ ▒░
"░      ░   ░ ░░ ░  ░ ░  ░    ░   ░      ░    ▒ ░  ░░   ░ 
"       ░   ░  ░      ░       ░  ░       ░    ░     ░     
"            

# Define color constants
RED="\x1B[01;31m"
GREEN="\x1B[38;2;145;191;31m"
GRAY="\x1B[01;90m"
CYAN="\x1B[01;36m"
RESET="\x1B[0m"

# Function to print colored text
print_colored_text() {
    local color=$1
    local message=$2

    case $color in
        "red")    color_code="$RED";;
        "green")  color_code="$GREEN";;
        "gray")   color_code="$GRAY";;
        "cyan")   color_code="$CYAN";;
        *)        echo "Error: Unsupported color." && return;;
    esac

    message_length=${#message}
    min_line_length=40
    line_length=$((message_length + 7 > min_line_length ? message_length + 7 : min_line_length))
    line=$(printf '%*s' "$line_length" | tr ' ' '-')

    echo -e "${color_code}$line$RESET"
    echo -e "${color_code}[*]   $message$RESET"
    echo -e "${color_code}$line$RESET"
}

# Print OS release information
cat /etc/redhat-release

# Service check function
check_service() {
    for service_name in "$@"; do
        if systemctl is-active --quiet $service_name; then
            start_time=$(systemctl show -p ActiveEnterTimestamp --value $service_name)
            current_time=$(date +%s)
            start_time_seconds=$(date --date="$start_time" +%s)
            uptime_seconds=$((current_time - start_time_seconds))
            uptime_formatted=$(date -u -d @"$uptime_seconds" +'%d days %H hours %M minutes %S seconds')
            print_colored_text "gray" "$service_name service has been running for $uptime_formatted."

            # Check if the service is "docker" and run docker ps command
            if [ "$service_name" == "docker" ]; then
                # Get Docker container status information
                docker_status=$(sudo docker ps --format "NAMES: {{.Names}} | CONTAINER ID: {{.ID}} | IMAGE: {{.Image}} | CREATED: {{.RunningFor}} | STATUS: {{.Status}} | PORTS: {{.Ports}}")
                echo -e "Docker Image Status:\n$docker_status"
                echo -e "$docker_status" >> "$CHEALTH_OUTPUT_PATH/output"
            fi
        else
            start_time=$(systemctl show -p ActiveEnterTimestamp --value $service_name)
            current_time=$(date +%s)
            start_time_seconds=$(date --date="$start_time" +%s)
            uptime_seconds=$((current_time - start_time_seconds))
            uptime_formatted=$(date -u -d @"$uptime_seconds" +'%d days %H hours %M minutes %S seconds')
            print_colored_text "red" "$service_name service has been down for $uptime_formatted."
        fi
    done
}

# Check specified services
check_service elasticsearch docker

# Version check function
version_check() {
    node_version=$(node --version)
    npm_version=$(npm --version)
    dotnet_info=$(dotnet --info)
    dotnet_version=$(echo "$dotnet_info" | awk '/Version:/ {print $2}')
    print_colored_text "cyan" "System Version:"
    echo "Node version: $node_version"
    echo "NPM version: $npm_version"
    echo "Dotnet version: $dotnet_version"
}

# Check system versions
version_check

# Specify the IP addresses or host names of Elasticsearch servers
elasticsearch_servers=("127.0.0.1")

# Elasticsearch check
print_colored_text "cyan" "Elasticsearch Check"

for server in "${elasticsearch_servers[@]}"; do
    echo "Elasticsearch Server: $server"

    version=$(curl -s -X GET "http://$server:9200/" | jq -r '.version.number')

    if [ -n "$version" ]; then
        echo "Elasticsearch Version: $version"
    else
        echo "Error: Unable to connect or retrieve version number."
    fi

    echo "------------------------"
done

# Get file modification time function
get_file_modification_time() {
    local file_path="$1"
    # Check if exiftool is installed
    if command -v exiftool > /dev/null; then
        # Use exiftool to get the File Modification Date/Time
        modification_time=$(exiftool -s -s -s -FileModifyDate "$file_path" 2>/dev/null)
        # If modification_time is not empty
        if [ -n "$modification_time" ]; then
            echo "File Modification Date/Time: $modification_time"
        else
            echo "Error: Unable to retrieve File Modification Date/Time using exiftool."
        fi
    else
        # Check if the file exists
        if [ -e "$file_path" ]; then
            # Use stat to get the modification time of the file
            modification_time=$(stat -c "%y" "$file_path" 2>/dev/null)
            # If modification_time is not empty
            if [ -n "$modification_time" ]; then
                echo "File Modification Date/Time: $modification_time"
            else
                echo "Error: Unable to retrieve File Modification Date/Time using stat."
            fi
        else
            echo "Error: File does not exist."
        fi
    fi
}

# File path for testing
file_path="/root/test.json"

# Version check for a file
print_colored_text "cyan" "Version Check"

if [ -e "$file_path" ]; then
    get_file_modification_time "$file_path"
else
    echo "File does not exist: $file_path"
fi

# Web service check
print_colored_text "cyan" "Web Service Check"

# Array containing web URLs
web_service=("https://localhost")

# Timeout duration (in seconds)
timeout_seconds=1

for url in "${web_service[@]}"; do
    response_code=$(timeout $timeout_seconds curl -s -o /dev/null -w "%{http_code}" --insecure $url 2>/dev/null)

    if [ $? -eq 0 ] && [ $response_code -eq 200 ]; then
        echo "$url: Web Service is working."
    else
        echo "$url: Web Service is not working or cannot get a response. HTTP Status Code: $response_code"
    fi
done
