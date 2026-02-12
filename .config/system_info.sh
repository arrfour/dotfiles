#!/bin/bash
# Cross-platform system info script for prompt.
# Detects OS and uses platform-appropriate commands.

OS=$(uname -s)
kernel=$(uname -r | cut -d'-' -f1)

# Platform-specific system info gathering.
if [[ "$OS" == "Linux" ]]; then
    distro=$(grep ^ID= /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"' || echo "linux")
    cpu=$(nproc 2>/dev/null || echo "N/A")
    mem=$(free -h 2>/dev/null | grep '^Mem:' | tr -s ' ' | cut -d' ' -f2 || echo "N/A")
elif [[ "$OS" == "Darwin" ]]; then
    # macOS
    distro="macOS"
    cpu=$(sysctl -n hw.ncpu 2>/dev/null || echo "N/A")
    mem=$(vm_stat 2>/dev/null | grep "Pages free" | awk '{print int($3 * 4096 / 1048576) "M"}' || echo "N/A")
elif [[ "$OS" == "FreeBSD" ]] || [[ "$OS" == "OpenBSD" ]]; then
    # BSD systems
    distro="${OS}"
    cpu=$(sysctl -n hw.ncpu 2>/dev/null || echo "N/A")
    mem=$(free -m 2>/dev/null | grep '^Mem:' | awk '{print $2 "M"}' || echo "N/A")
else
    # Fallback for unknown OS
    distro="unknown"
    cpu="N/A"
    mem="N/A"
fi

echo "${distro} ${kernel} | ${cpu}C | ${mem}"
