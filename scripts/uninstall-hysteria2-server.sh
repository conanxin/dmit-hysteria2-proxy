#!/usr/bin/env bash
# uninstall-hysteria2-server.sh — Gracefully remove Hysteria 2 from the system
set -euo pipefail

echo "=== Hysteria 2 Uninstall ==="
echo ""
echo "WARNING: This will stop and remove the Hysteria 2 server."
echo "Your 3X-UI / Xray Reality will NOT be affected."
echo ""

if [[ $EUID -ne 0 ]]; then
    echo "[FAIL] This script must be run as root."
    exit 1
fi

# Stop and disable service
if systemctl is-active --quiet hysteria-server 2>/dev/null; then
    echo "[INFO] Stopping hysteria-server.service..."
    systemctl stop hysteria-server.service
fi

if systemctl is-enabled --quiet hysteria-server 2>/dev/null; then
    echo "[INFO] Disabling hysteria-server.service..."
    systemctl disable hysteria-server.service
fi

# Remove systemd unit
if [[ -f /etc/systemd/system/hysteria-server.service ]]; then
    rm -f /etc/systemd/system/hysteria-server.service
    systemctl daemon-reload
    echo "[INFO] Removed systemd unit."
fi

# Remove config
if [[ -d /etc/hysteria ]]; then
    rm -rf /etc/hysteria
    echo "[INFO] Removed /etc/hysteria/."
fi

# Remove binary
if command -v hysteria &>/dev/null; then
    HY2_PATH=$(which hysteria)
    rm -f "${HY2_PATH}"
    echo "[INFO] Removed hysteria binary."
fi

# Remove client info
rm -f /root/hysteria2-client-info.txt

echo ""
echo "[PASS] Hysteria 2 has been uninstalled."
echo "[INFO] 3X-UI / Xray Reality is unaffected."
