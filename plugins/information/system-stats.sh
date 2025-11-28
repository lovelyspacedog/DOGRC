#!/bin/bash
# Sourcing Guard - check if system-stats function already exists
if declare -f system-stats >/dev/null 2>&1; then
    return 0
fi

[[ -z "${__INFORMATION_DIR:-}" ]] && readonly __INFORMATION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${__PLUGINS_DIR:-}" ]] && readonly __PLUGINS_DIR="$(cd "${__INFORMATION_DIR}/.." && pwd)"
[[ -z "${__CORE_DIR:-}" ]] && readonly __CORE_DIR="$(cd "${__INFORMATION_DIR}/../../core" && pwd)"
[[ -z "${__DOGRC_DIR:-}" ]] && readonly __DOGRC_DIR="$(cd "${__INFORMATION_DIR}/../.." && pwd)"

source "${__CORE_DIR}/dependency_check.sh"

system-stats() {
    # Handle help flags (case-insensitive)
    if [[ -n "${1:-}" ]] && { [[ "${1,,}" == "--help" ]] || [[ "${1,,}" == "-h" ]]; }; then
        if declare -f drchelp >/dev/null 2>&1; then
            drchelp system-stats
            return 0
        else
            echo "Error: drchelp not available" >&2
            return 1
        fi
    fi
    
    # Check for required commands (basic ones that should always be available)
    ensure_commands_present --caller "system-stats" free df uptime || {
        return $?
    }
    
    local watch_mode=false
    local json_mode=false
    local interval=2
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --watch|-w)
                watch_mode=true
                shift
                ;;
            --json|-j)
                json_mode=true
                shift
                ;;
            --interval|-i)
                if [[ -n "${2:-}" ]] && [[ "$2" =~ ^[0-9]+$ ]]; then
                    interval="$2"
                    shift 2
                else
                    echo "Error: --interval requires a numeric argument (seconds)" >&2
                    return 1
                fi
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
                # Unknown argument
                echo "Error: Unknown argument $1" >&2
                return 1
                ;;
        esac
    done
    
    # Function to collect system statistics
    collect_stats() {
        local stats_json=false
        [[ "$1" == "json" ]] && stats_json=true
        
        # CPU Usage
        local cpu_usage="N/A"
        if command -v top >/dev/null 2>&1; then
            cpu_usage=$(top -bn1 | grep -i "Cpu(s)" | awk '{print $2}' | sed 's/%us,//' | head -1)
            [[ -z "$cpu_usage" ]] && cpu_usage=$(top -bn1 | grep -i "Cpu(s)" | awk -F'%' '{print $1}' | awk '{print $2}')
        elif command -v vmstat >/dev/null 2>&1; then
            cpu_usage=$(vmstat 1 2 | tail -1 | awk '{print 100 - $15"%"}')
        fi
        
        # Memory Usage
        local mem_total mem_used mem_free mem_available mem_percent
        if command -v free >/dev/null 2>&1; then
            if free -h >/dev/null 2>&1; then
                # Linux
                mem_total=$(free -h | grep "^Mem:" | awk '{print $2}')
                mem_used=$(free -h | grep "^Mem:" | awk '{print $3}')
                mem_free=$(free -h | grep "^Mem:" | awk '{print $4}')
                mem_available=$(free -h | grep "^Mem:" | awk '{print $7}')
                mem_percent=$(free | grep "^Mem:" | awk '{printf "%.1f", ($3/$2) * 100}')
            else
                # macOS/BSD
                mem_total=$(free | grep "^Mem:" | awk '{print $2}')
                mem_used=$(free | grep "^Mem:" | awk '{print $3}')
                mem_free=$(free | grep "^Mem:" | awk '{print $4}')
                mem_available="$mem_free"
                mem_percent=$(free | grep "^Mem:" | awk '{printf "%.1f", ($3/$2) * 100}')
            fi
        fi
        
        # Disk Usage
        local disk_usage=""
        if command -v df >/dev/null 2>&1; then
            # Get root filesystem usage
            if df -h / >/dev/null 2>&1; then
                disk_usage=$(df -h / | tail -1 | awk '{print $5}')
            else
                disk_usage=$(df / | tail -1 | awk '{print $5}')
            fi
        fi
        
        # Network Stats (if available)
        local network_rx="N/A"
        local network_tx="N/A"
        if command -v ip >/dev/null 2>&1; then
            # Linux: use ip command to find default interface
            local iface=$(ip route 2>/dev/null | grep default | awk '{print $5}' | head -1)
            if [[ -z "$iface" ]]; then
                # Fallback: try to find first active interface
                for potential_iface in /sys/class/net/*; do
                    if [[ -d "$potential_iface" ]] && [[ "$potential_iface" != *"lo"* ]]; then
                        iface=$(basename "$potential_iface")
                        break
                    fi
                done
            fi
            if [[ -n "$iface" ]] && [[ -f "/sys/class/net/$iface/statistics/rx_bytes" ]] && [[ -f "/sys/class/net/$iface/statistics/tx_bytes" ]]; then
                local rx_bytes=$(cat "/sys/class/net/$iface/statistics/rx_bytes" 2>/dev/null | tr -d '[:space:]')
                local tx_bytes=$(cat "/sys/class/net/$iface/statistics/tx_bytes" 2>/dev/null | tr -d '[:space:]')
                if [[ -n "$rx_bytes" ]] && [[ "$rx_bytes" =~ ^[0-9]+$ ]] && [[ -n "$tx_bytes" ]] && [[ "$tx_bytes" =~ ^[0-9]+$ ]]; then
                    # Convert to human-readable format
                    if command -v numfmt >/dev/null 2>&1; then
                        network_rx=$(numfmt --to=iec-i --suffix=B "$rx_bytes" 2>/dev/null || echo "${rx_bytes}B")
                        network_tx=$(numfmt --to=iec-i --suffix=B "$tx_bytes" 2>/dev/null || echo "${tx_bytes}B")
                    else
                        # Fallback: simple conversion using awk
                        if [[ $rx_bytes -ge 1073741824 ]]; then
                            network_rx=$(awk "BEGIN {printf \"%.2fGiB\", $rx_bytes/1073741824}" 2>/dev/null || echo "${rx_bytes}B")
                        elif [[ $rx_bytes -ge 1048576 ]]; then
                            network_rx=$(awk "BEGIN {printf \"%.2fMiB\", $rx_bytes/1048576}" 2>/dev/null || echo "${rx_bytes}B")
                        elif [[ $rx_bytes -ge 1024 ]]; then
                            network_rx=$(awk "BEGIN {printf \"%.2fKiB\", $rx_bytes/1024}" 2>/dev/null || echo "${rx_bytes}B")
                        else
                            network_rx="${rx_bytes}B"
                        fi
                        if [[ $tx_bytes -ge 1073741824 ]]; then
                            network_tx=$(awk "BEGIN {printf \"%.2fGiB\", $tx_bytes/1073741824}" 2>/dev/null || echo "${tx_bytes}B")
                        elif [[ $tx_bytes -ge 1048576 ]]; then
                            network_tx=$(awk "BEGIN {printf \"%.2fMiB\", $tx_bytes/1048576}" 2>/dev/null || echo "${tx_bytes}B")
                        elif [[ $tx_bytes -ge 1024 ]]; then
                            network_tx=$(awk "BEGIN {printf \"%.2fKiB\", $tx_bytes/1024}" 2>/dev/null || echo "${tx_bytes}B")
                        else
                            network_tx="${tx_bytes}B"
                        fi
                    fi
                fi
            fi
        elif command -v ifconfig >/dev/null 2>&1; then
            # macOS/BSD: use ifconfig
            local iface=$(route get default 2>/dev/null | grep interface | awk '{print $2}' || echo "en0")
            if [[ -n "$iface" ]] && ifconfig "$iface" >/dev/null 2>&1; then
                # Try to extract RX/TX bytes from ifconfig output
                local rx_info=$(ifconfig "$iface" 2>/dev/null | grep -i "RX packets" | head -1)
                local tx_info=$(ifconfig "$iface" 2>/dev/null | grep -i "TX packets" | head -1)
                if [[ -n "$rx_info" ]] && [[ -n "$tx_info" ]]; then
                    # Extract bytes (format varies by system)
                    local rx_bytes=$(echo "$rx_info" | grep -oE '[0-9]+ bytes' | head -1 | awk '{print $1}')
                    local tx_bytes=$(echo "$tx_info" | grep -oE '[0-9]+ bytes' | head -1 | awk '{print $1}')
                    if [[ -n "$rx_bytes" ]] && [[ -n "$tx_bytes" ]]; then
                        network_rx="${rx_bytes}B"
                        network_tx="${tx_bytes}B"
                    fi
                fi
            fi
        fi
        
        # Uptime
        local uptime_str="N/A"
        if command -v uptime >/dev/null 2>&1; then
            uptime_str=$(uptime -p 2>/dev/null || uptime | awk -F'up' '{print $2}' | awk -F',' '{print $1}' | sed 's/^ *//')
        fi
        
        # Load Average
        local load_avg="N/A"
        if [[ -f /proc/loadavg ]]; then
            load_avg=$(cat /proc/loadavg | awk '{print $1", "$2", "$3}')
        elif command -v uptime >/dev/null 2>&1; then
            load_avg=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^ *//')
        fi
        
        # Output based on mode
        if [[ "$stats_json" == true ]]; then
            # JSON output
            echo "{"
            echo "  \"cpu\": {"
            echo "    \"usage\": \"$cpu_usage\""
            echo "  },"
            echo "  \"memory\": {"
            echo "    \"total\": \"$mem_total\","
            echo "    \"used\": \"$mem_used\","
            echo "    \"free\": \"$mem_free\","
            echo "    \"available\": \"$mem_available\","
            echo "    \"percent\": $mem_percent"
            echo "  },"
            echo "  \"disk\": {"
            echo "    \"usage\": \"$disk_usage\""
            echo "  },"
            echo "  \"network\": {"
            echo "    \"rx\": \"$network_rx\","
            echo "    \"tx\": \"$network_tx\""
            echo "  },"
            echo "  \"system\": {"
            echo "    \"uptime\": \"$uptime_str\","
            echo "    \"load_average\": \"$load_avg\""
            echo "  }"
            echo "}"
        else
            # Human-readable output
            echo "═══════════════════════════════════════════════════════════"
            echo "                    SYSTEM STATISTICS"
            echo "═══════════════════════════════════════════════════════════"
            echo
            echo "CPU Usage:        $cpu_usage"
            echo
            echo "Memory:"
            echo "  Total:          $mem_total"
            echo "  Used:           $mem_used ($mem_percent%)"
            echo "  Free:           $mem_free"
            echo "  Available:      $mem_available"
            echo
            echo "Disk Usage (/):   $disk_usage"
            echo
            echo "Network:"
            echo "  RX:             $network_rx"
            echo "  TX:             $network_tx"
            echo
            echo "System:"
            echo "  Uptime:         $uptime_str"
            echo "  Load Average:   $load_avg"
            echo "═══════════════════════════════════════════════════════════"
        fi
    }
    
    # Main execution
    if [[ "$watch_mode" == true ]]; then
        # Watch mode - continuously update
        while true; do
            clear
            collect_stats "$([[ "$json_mode" == true ]] && echo "json" || echo "text")"
            sleep "$interval"
        done
    else
        # Single run
        collect_stats "$([[ "$json_mode" == true ]] && echo "json" || echo "text")"
    fi
    
    return 0
}

# Tab completion function
_system_stats_completion() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # If current word starts with dash, complete with flags
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "--watch -w --json -j --interval -i --help -h --" -- "$cur"))
        return 0
    fi
    
    # If previous word is --interval, complete with numbers (optional)
    if [[ "$prev" == "--interval" ]] || [[ "$prev" == "-i" ]]; then
        COMPREPLY=()
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
        complete -F _system_stats_completion system-stats 2>/dev/null || true
    fi
fi

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    system-stats "$@"
    exit $?
fi

