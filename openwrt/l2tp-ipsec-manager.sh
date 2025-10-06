#!/bin/sh
# L2TP/IPSec tunnel management script for OpenWRT
# Logging to /var/log/l2tp-ipsec-restart.log

LOG_FILE="/var/log/l2tp-ipsec-restart.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Logging function
log_message() {
    echo "[$TIMESTAMP] $1" >> "$LOG_FILE"
    logger -t "l2tp-ipsec-manager" "$1"
}

# Dependency check function
check_dependencies() {
    for dep in xl2tpd ipsec; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            log_message "ERROR: $dep not found"
            exit 1
        fi
    done
}

# Process finding and termination function
kill_services() {
    log_message "Searching for running processes..."
    
    # Find and kill xl2tpd
    XL2TPD_PID=$(ps | grep -v grep | grep xl2tpd | awk '{print $1}')
    if [ -n "$XL2TPD_PID" ]; then
        log_message "Terminating xl2tpd (PID: $XL2TPD_PID)"
        kill "$XL2TPD_PID" 2>/dev/null
        sleep 2
        # Force kill if needed
        if ps | grep -q "$XL2TPD_PID"; then
            kill -9 "$XL2TPD_PID" 2>/dev/null
            log_message "Force terminating xl2tpd"
        fi
    fi

    # Find and kill IPSec daemons
    IPSEC_PIDS=$(ps | grep -v grep | grep -E 'charon|pluto|strongswan' | awk '{print $1}')
    if [ -n "$IPSEC_PIDS" ]; then
        log_message "Terminating IPSec daemons (PIDs: $IPSEC_PIDS)"
        echo "$IPSEC_PIDS" | xargs kill 2>/dev/null
        sleep 3
        # Cleanup remaining processes
        ps | grep -v grep | grep -E 'charon|pluto|strongswan' | awk '{print $1}' | xargs kill -9 2>/dev/null
    fi

    # Additional interface and session cleanup
    ipsec stop 2>/dev/null
    log_message "Cleanup completed"
}

# Service startup function
start_services() {
    log_message "Starting services..."
    
    # Start StrongSwan
    if ipsec start 2>/dev/null; then
        log_message "StrongSwan started"
    else
        log_message "ERROR: Failed to start StrongSwan"
        return 1
    fi
    
    sleep 2

    # Start xl2tpd
    if xl2tpd -D 2>/dev/null & then
        log_message "xl2tpd started"
    else
        log_message "ERROR: Failed to start xl2tpd"
        return 1
    fi
    
    sleep 2
    
    # Tunnel initialization (if needed)
    if [ -p /var/run/xl2tpd/l2tp-control ]; then
        echo "c mytunnel" > /var/run/xl2tpd/l2tp-control 2>/dev/null
        log_message "L2TP tunnel initialized"
    fi
}

# Status check function
check_status() {
    log_message "Checking service status..."
    
    # Check IPSec starter
    if ps | grep -v grep | grep -q charon; then
        log_message "IPSec (charon with starter functional) is running"
    else
        log_message "IPSec (charon with starter functional) is NOT running"
        return 1
    fi
    
    # Check xl2tpd
    if ps | grep -v grep | grep -q xl2tpd; then
        log_message "xl2tpd is running"
    else
        log_message "xl2tpd is NOT running"
        return 1
    fi
    
    # Check tunnel (optional)
    if ip addr show | grep -q ppp; then
        log_message "PPP interface detected"
    else
        log_message "PPP interface NOT detected"
    fi
}

## Main function
main() {
    log_message "=== Starting L2TP/IPSec restart procedure ==="
    
    # Check dependencies
    check_dependencies
    
    # Stop services
    kill_services
    sleep 5
    
    # Start services
    if start_services; then
        sleep 5
        if check_status; then
            log_message "Procedure completed SUCCESSFULLY"
            exit 0
        else
            log_message "WARNING: Services started but there are issues"
            exit 1
        fi
    else
        log_message "Procedure completed with ERRORS"
        exit 1
    fi
}

# Call main function
main "$@"