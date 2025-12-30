#!/usr/bin/env bash

# Common utility functions for scripts

# Print colored text
print_color() {
    case $1 in
        red)    echo -e "\033[31m$2\033[0m";;
        green)  echo -e "\033[32m$2\033[0m";;
        yellow) echo -e "\033[33m$2\033[0m";;
        blue)   echo -e "\033[34m$2\033[0m";;
        *)      echo "$2";;
    esac
}

# Print error to stderr in red
error() {
    print_color red "Error: $*" >&2
}

# Print error and exit
fatal() {
    error "$*"
    exit 1
}

# Set source and root directories, cd to root
set_source_and_root_dir() {
    { set +x; } 2>/dev/null
    source_dir="$( cd -P "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
    root_dir=$(cd "$source_dir" && cd ../ && pwd)
    cd "$root_dir"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Print warning in yellow
warning() {
    print_color yellow "Warning: $*" >&2
}

# Print success in green
success() {
    print_color green "✓ $*"
}

# Check required commands exist
require_commands() {
    local missing=()
    for cmd in "$@"; do
        command_exists "$cmd" || missing+=("$cmd")
    done
    [ ${#missing[@]} -eq 0 ] || fatal "Missing commands: ${missing[*]}"
}

# Show help from script comments
show_help() {
    sed -n 's/^#\/ \?//p' "$0"
}

# Find process using a port
# Usage: find_port_process <port>
# Outputs: "pid:process_name" if found, nothing if not found
# Example: result=$(find_port_process 8080); if [ -n "$result" ]; then echo "Found: $result"; fi
find_port_process() {
    local port=$1
    local pid=""
    
    # Validate input
    if [ -z "$port" ]; then
        echo "Error: Port number required" >&2
        return 1
    fi
    
    # Helper function to format output
    format_output() {
        local pid=$1
        [ -n "$pid" ] && [ "$pid" != "-" ] || return 1
        local process_name=$(ps -p "$pid" -o comm= 2>/dev/null || echo "unknown")
        echo "$pid:$process_name"
        return 0
    }
    
    # Try lsof first (most reliable)
    if command_exists lsof; then
        pid=$(lsof -ti ":$port" 2>/dev/null | head -1)
        format_output "$pid" && return 0
    fi
    
    # Try ss (Linux)
    if command_exists ss; then
        pid=$(ss -tlnp 2>/dev/null | grep ":$port " | head -1 | grep -o 'pid=[0-9]*' | cut -d= -f2)
        format_output "$pid" && return 0
    fi
    
    # Try netstat (fallback)
    if command_exists netstat; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS: netstat output format is different
            pid=$(netstat -anv 2>/dev/null | grep "\\.$port " | grep LISTEN | awk '{print $9}' | head -1)
        else
            # Linux: extract PID from netstat
            pid=$(netstat -tlnp 2>/dev/null | grep ":$port " | head -1 | awk '{print $7}' | cut -d/ -f1)
        fi
        format_output "$pid" && return 0
    fi
    
    # No process found
    return 0
}