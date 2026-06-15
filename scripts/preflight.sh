#!/usr/bin/env bash
# preflight.sh — Environment readiness check for Hysteria 2 deployment
set -euo pipefail

echo "=== Hysteria 2 Preflight Check ==="
echo ""

# 1. Root check
if [[ $EUID -ne 0 ]]; then
    echo "[FAIL] This script must be run as root."
    exit 1
fi
echo "[PASS] Running as root."

# 2. Architecture check
ARCH=$(uname -m)
echo "[INFO] Architecture: ${ARCH}"
if [[ "${ARCH}" != "x86_64" && "${ARCH}" != "aarch64" ]]; then
    echo "[FAIL] Unsupported architecture: ${ARCH}"
    exit 1
fi
echo "[PASS] Architecture supported."

# 3. Systemd check
if ! command -v systemctl &>/dev/null; then
    echo "[FAIL] systemd not found."
    exit 1
fi
echo "[PASS] systemd available."

# 4. Check x-ui status
if systemctl is-active --quiet x-ui 2>/dev/null; then
    echo "[INFO] x-ui.service is ACTIVE — will coexist with Hysteria 2."
else
    echo "[WARN] x-ui.service not found or inactive."
fi

# 5. Check TCP 443
if ss -tlnp 2>/dev/null | grep -q ':443\b'; then
    TCP_443_PROC=$(ss -tlnp 2>/dev/null | grep ':443\b' | awk '{print $NF}')
    echo "[INFO] TCP 443 occupied by: ${TCP_443_PROC}"
    echo "[INFO] This is expected — Hysteria 2 will use UDP 443 only."
else
    echo "[WARN] TCP 443 is NOT occupied — is 3X-UI / Reality running?"
fi

# 6. Check UDP 443
if ss -ulnp 2>/dev/null | grep -q ':443\b'; then
    UDP_443_PROC=$(ss -ulnp 2>/dev/null | grep ':443\b' | awk '{print $NF}')
    echo "[FAIL] UDP 443 is already occupied by: ${UDP_443_PROC}"
    echo "Cannot deploy Hysteria 2 — port conflict on UDP 443."
    exit 1
fi
echo "[PASS] UDP 443 is available for Hysteria 2."

# 7. Check if hysteria is already installed
if command -v hysteria &>/dev/null; then
    HY2_VER=$(hysteria version 2>/dev/null | head -1 || echo "unknown")
    echo "[INFO] Hysteria already installed: ${HY2_VER}"
else
    echo "[INFO] Hysteria not yet installed."
fi

# 8. Domain DNS check (if HY2_DOMAIN is set)
if [[ -n "${HY2_DOMAIN:-}" ]]; then
    if command -v dig &>/dev/null; then
        DOMAIN_IP=$(dig +short "${HY2_DOMAIN}" A 2>/dev/null || true)
    elif command -v nslookup &>/dev/null; then
        DOMAIN_IP=$(nslookup "${HY2_DOMAIN}" 2>/dev/null | awk '/^Address: / {print $2}' | tail -1 || true)
    else
        DOMAIN_IP=""
    fi
    if [[ -z "${DOMAIN_IP}" ]]; then
        echo "[WARN] Could not resolve ${HY2_DOMAIN} — DNS may not be configured yet."
    else
        VPS_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
        echo "[INFO] ${HY2_DOMAIN} resolves to ${DOMAIN_IP}"
        if [[ "${DOMAIN_IP}" == "${VPS_IP}" ]]; then
            echo "[PASS] DNS A record points to this VPS (${VPS_IP})."
        else
            echo "[WARN] DNS A record (${DOMAIN_IP}) does not match VPS IP (${VPS_IP})."
        fi
    fi
fi

echo ""
echo "=== Preflight Complete ==="
