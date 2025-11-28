#!/bin/bash
# Sourcing Guard - check if network-info function already exists
if declare -f network-info >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__INFORMATION_DIR:-}" ]] && readonly __INFORMATION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__INFORMATION_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__INFORMATION_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__INFORMATION_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

network-info() {
    # Handle help flags (case-insensitive)
    if [[ -n "${1:-}" ]] && { [[ "${1,,}" == "--help" ]] || [[ "${1,,}" == "-h" ]]; }; then
        if declare -f drchelp >/dev/null 2>&1; then
            drchelp network-info
            return 0
        else
            echo "Error: drchelp not available" >&2
            return 1
        fi
    fi
    
    # Check for at least one network tool
    local has_ip=false
    local has_ifconfig=false
    local has_ss=false
    local has_netstat=false
    
    command -v ip >/dev/null 2>&1 && has_ip=true
    command -v ifconfig >/dev/null 2>&1 && has_ip=true && has_ifconfig=true
    command -v ss >/dev/null 2>&1 && has_ss=true
    command -v netstat >/dev/null 2>&1 && has_netstat=true
    
    if [[ "$has_ip" == false ]] && [[ "$has_ifconfig" == false ]]; then
        echo "Error: network-info requires 'ip' or 'ifconfig' command" >&2
        return 1
    fi
    
    local show_speed=false
    local show_ports=false
    local show_connections=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --speed|-s)
                show_speed=true
                shift
                ;;
            --ports|-p)
                show_ports=true
                shift
                ;;
            --connections|-c)
                show_connections=true
                shift
                ;;
            --)
                shift
                break
                ;;
            -*)
                echo "Error: Unknown option $1" >&2
                return 1
                ;;
            *)
                echo "Error: Unknown argument $1" >&2
                return 1
                ;;
        esac
    done
    
    # Function to show network interfaces and IPs
    show_interfaces() {
        echo "═══════════════════════════════════════════════════════════"
        echo "                  NETWORK INTERFACES"
        echo "═══════════════════════════════════════════════════════════"
        echo
        
        if [[ "$has_ip" == true ]] && command -v ip >/dev/null 2>&1; then
            # Use ip command (Linux)
            echo "Interfaces and IP Addresses:"
            echo
            ip -4 addr show 2>/dev/null | grep -E "^[0-9]+:|inet " | while IFS= read -r line; do
                if [[ "$line" =~ ^[0-9]+: ]]; then
                    # Interface name
                    interface=$(echo "$line" | awk -F': ' '{print $2}' | awk '{print $1}')
                    echo "  $interface:"
                elif [[ "$line" =~ inet ]]; then
                    # IP address
                    ip_addr=$(echo "$line" | awk '{print $2}')
                    echo "    IP: $ip_addr"
                fi
            done
            
            # Show default gateway
            echo
            echo "Default Gateway:"
            default_gw=$(ip route 2>/dev/null | grep default | awk '{print $3}' | head -1)
            if [[ -n "$default_gw" ]]; then
                echo "  $default_gw"
            else
                echo "  Not configured"
            fi
            
            # Show DNS servers
            echo
            echo "DNS Servers:"
            if [[ -f /etc/resolv.conf ]]; then
                dns_servers=$(grep -E "^nameserver" /etc/resolv.conf 2>/dev/null | awk '{print $2}' | head -3)
                if [[ -n "$dns_servers" ]]; then
                    echo "$dns_servers" | while read -r dns; do
                        echo "  $dns"
                    done
                else
                    echo "  Not configured"
                fi
            else
                echo "  Not available"
            fi
        elif [[ "$has_ifconfig" == true ]] && command -v ifconfig >/dev/null 2>&1; then
            # Use ifconfig (macOS/BSD)
            echo "Interfaces and IP Addresses:"
            echo
            ifconfig 2>/dev/null | grep -E "^[a-z]|inet " | while IFS= read -r line; do
                if [[ "$line" =~ ^[a-z] ]] && [[ ! "$line" =~ ^[[:space:]] ]]; then
                    # Interface name
                    interface=$(echo "$line" | awk -F': ' '{print $1}')
                    echo "  $interface:"
                elif [[ "$line" =~ inet ]]; then
                    # IP address
                    ip_addr=$(echo "$line" | awk '{print $2}')
                    echo "    IP: $ip_addr"
                fi
            done
            
            # Show default gateway (macOS)
            echo
            echo "Default Gateway:"
            default_gw=$(route get default 2>/dev/null | grep gateway | awk '{print $2}')
            if [[ -n "$default_gw" ]]; then
                echo "  $default_gw"
            else
                echo "  Not configured"
            fi
        fi
        echo "═══════════════════════════════════════════════════════════"
    }
    
    # Function to test network speed
    test_speed() {
        echo "═══════════════════════════════════════════════════════════"
        echo "                  NETWORK SPEED TEST"
        echo "═══════════════════════════════════════════════════════════"
        echo
        
        if command -v speedtest-cli >/dev/null 2>&1; then
            echo "Running speed test (this may take a minute)..."
            echo
            speedtest-cli --simple 2>/dev/null || {
                echo "Error: Speed test failed. Trying alternative method..." >&2
                speedtest-cli 2>/dev/null || {
                    echo "Error: Unable to run speed test. Please install speedtest-cli." >&2
                    return 1
                }
            }
        elif command -v speedtest >/dev/null 2>&1; then
            echo "Running speed test (this may take a minute)..."
            echo
            speedtest --simple 2>/dev/null || {
                echo "Error: Speed test failed." >&2
                return 1
            }
        else
            echo "Error: speedtest-cli or speedtest command not found." >&2
            echo "Install it with:" >&2
            echo "  pip install speedtest-cli" >&2
            echo "  or" >&2
            echo "  pip install speedtest-cli2" >&2
            return 1
        fi
        echo "═══════════════════════════════════════════════════════════"
    }
    
    # Function to show listening ports
    show_ports() {
        echo "═══════════════════════════════════════════════════════════"
        echo "                  LISTENING PORTS"
        echo "═══════════════════════════════════════════════════════════"
        echo
        
        if [[ "$has_ss" == true ]] && command -v ss >/dev/null 2>&1; then
            # Use ss command (Linux, preferred) - use -H to suppress headers
            echo "Port          Protocol  Process"
            echo "───────────────────────────────────────────────────────"
            ss -tulpnH 2>/dev/null | grep LISTEN | awk '
                {
                    local_addr = $5
                    netid = $1
                    # Extract process name from remaining fields
                    process = ""
                    for (i = 7; i <= NF; i++) {
                        process = process " " $i
                    }
                    # Clean up process name
                    gsub(/users:\(\(/, "", process)
                    gsub(/\)\)/, "", process)
                    gsub(/^[ ]+/, "", process)
                    gsub(/[ ]+$/, "", process)
                    # Extract just the command name
                    split(process, parts, ",")
                    proc_name = parts[1]
                    gsub(/.*\//, "", proc_name)
                    # Remove quotes using character class
                    gsub(/["]/, "", proc_name)
                    if (length(proc_name) > 20) {
                        proc_name = substr(proc_name, 1, 20)
                    }
                    if (proc_name == "") {
                        proc_name = "N/A"
                    }
                    printf "%-14s %-10s %s\n", local_addr, netid, proc_name
                }
            ' | head -20
        elif [[ "$has_netstat" == true ]] && command -v netstat >/dev/null 2>&1; then
            # Use netstat (fallback)
            if netstat -tulpn >/dev/null 2>&1; then
                # Linux netstat
                echo "Port  Protocol  Process"
                echo "───────────────────────────────────────────────────────"
                netstat -tulpn 2>/dev/null | grep LISTEN | awk '{printf "%-8s %-10s %s\n", $4, $1, $7}' | sed 's/.*://' | sort -n | head -20
            else
                # macOS/BSD netstat
                echo "Port  Protocol"
                echo "───────────────────────────────────────────────────────"
                netstat -an 2>/dev/null | grep LISTEN | awk '{printf "%-8s %s\n", $4, $1}' | sed 's/.*://' | sort -n | head -20
            fi
        else
            echo "Error: 'ss' or 'netstat' command not found" >&2
            echo "Install ss: sudo apt install iproute2  # Debian/Ubuntu" >&2
            echo "           sudo yum install iproute    # RHEL/CentOS" >&2
            echo "Install netstat: sudo apt install net-tools  # Debian/Ubuntu" >&2
            return 1
        fi
        echo "═══════════════════════════════════════════════════════════"
    }
    
    # Function to show active connections
    show_connections() {
        echo "═══════════════════════════════════════════════════════════"
        echo "                  ACTIVE CONNECTIONS"
        echo "═══════════════════════════════════════════════════════════"
        echo
        
        if [[ "$has_ss" == true ]] && command -v ss >/dev/null 2>&1; then
            # Use ss command (Linux, preferred) - use -H to suppress headers
            echo "Local Address          Remote Address         State"
            echo "────────────────────────────────────────────────────────────────────"
            ss -tunH 2>/dev/null | awk '
                /LISTEN/ { next }
                $5 ~ /:/ && $6 ~ /:/ && ($1 == "tcp" || $1 == "udp" || $1 == "tcp6" || $1 == "udp6") {
                    printf "%-22s %-22s %s\n", $5, $6, $2
                }
            ' | head -20
        elif [[ "$has_netstat" == true ]] && command -v netstat >/dev/null 2>&1; then
            # Use netstat (fallback)
            if netstat -tun >/dev/null 2>&1; then
                # Linux netstat
                echo "Local Address          Remote Address         State"
                echo "────────────────────────────────────────────────────────────────────"
                netstat -tun 2>/dev/null | grep -v LISTEN | awk '{printf "%-22s %-22s %s\n", $4, $5, $6}' | head -20
            else
                # macOS/BSD netstat
                echo "Local Address          Remote Address         State"
                echo "────────────────────────────────────────────────────────────────────"
                netstat -an 2>/dev/null | grep ESTABLISHED | awk '{printf "%-22s %-22s %s\n", $4, $5, $6}' | head -20
            fi
        else
            echo "Error: 'ss' or 'netstat' command not found" >&2
            return 1
        fi
        echo "═══════════════════════════════════════════════════════════"
    }
    
    # Main execution
    local something_shown=false
    
    # Default: show interfaces if no specific flag is set
    if [[ "$show_speed" == false ]] && [[ "$show_ports" == false ]] && [[ "$show_connections" == false ]]; then
        show_interfaces
        something_shown=true
    fi
    
    # Show speed if requested
    if [[ "$show_speed" == true ]]; then
        [[ "$something_shown" == true ]] && echo
        test_speed
        something_shown=true
    fi
    
    # Show ports if requested
    if [[ "$show_ports" == true ]]; then
        [[ "$something_shown" == true ]] && echo
        show_ports
        something_shown=true
    fi
    
    # Show connections if requested
    if [[ "$show_connections" == true ]]; then
        [[ "$something_shown" == true ]] && echo
        show_connections
        something_shown=true
    fi
    
    return 0
}

# Tab completion function
_network_info_completion() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # If current word starts with dash, complete with flags
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "--speed -s --ports -p --connections -c --help -h --" -- "$cur"))
        return 0
    fi
    
    # Otherwise, no completion
    COMPREPLY=()
    return 0
}

# Register the completion function
# Only register if we're in an interactive shell and bash-completion is available
if [[ -n "${BASH_VERSION:-}" ]] && [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Check if complete command is available (bash-completion)
    if command -v complete >/dev/null 2>&1; then
        complete -F _network_info_completion network-info 2>/dev/null || true
    fi
fi

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    network-info "$@"
    exit $?
fi

