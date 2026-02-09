#!/bin/bash
distro=$(grep ^ID= /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"' || echo "linux")
kernel=$(uname -r | cut -d'-' -f1)
cpu=$(nproc)
mem=$(free -h 2>/dev/null | grep '^Mem:' | tr -s ' ' | cut -d' ' -f2 || echo "N/A")
echo "${distro} ${kernel} | ${cpu}C | ${mem}"
