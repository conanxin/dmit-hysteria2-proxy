#!/usr/bin/env bash
# render-server-config.sh — Render Hysteria 2 server config from template
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"

# Load env
HY2_DOMAIN="${HY2_DOMAIN:-}"
HY2_PORT="${HY2_PORT:-443}"
HY2_USER="${HY2_USER:-conan-main}"
HY2_AUTH_PASSWORD="${HY2_AUTH_PASSWORD:-}"
HY2_OBFS_PASSWORD="${HY2_OBFS_PASSWORD:-}"
HY2_TRAFFIC_SECRET="${HY2_TRAFFIC_SECRET:-}"
HY2_MASQUERADE_URL="${HY2_MASQUERADE_URL:-https://www.apple.com/}"
HY2_BANDWIDTH_UP="${HY2_BANDWIDTH_UP:-100 mbps}"
HY2_BANDWIDTH_DOWN="${HY2_BANDWIDTH_DOWN:-100 mbps}"

echo "=== Rendering Hysteria 2 Server Config ==="

# Check required vars
if [[ -z "${HY2_DOMAIN}" ]]; then
    echo "[FAIL] HY2_DOMAIN is required."
    exit 1
fi

# Certificate detection
# Hysteria runs as user 'hysteria' which cannot access /root/.
# All certs must be copied to /etc/hysteria/certs/ with proper ownership.
CERT_FOUND=false
HY2_CERT=""
HY2_KEY=""
TEMPLATE=""
RAW_CERT=""
RAW_KEY=""

# Check Let's Encrypt
if [[ -f "/etc/letsencrypt/live/${HY2_DOMAIN}/fullchain.pem" ]]; then
    RAW_CERT="/etc/letsencrypt/live/${HY2_DOMAIN}/fullchain.pem"
    RAW_KEY="/etc/letsencrypt/live/${HY2_DOMAIN}/privkey.pem"
    CERT_FOUND=true
    echo "[INFO] Found Let's Encrypt certificate."
fi

# Check acme.sh (ecc) — need to copy out of /root/ for hysteria user
if [[ "${CERT_FOUND}" == "false" && -f "/root/.acme.sh/${HY2_DOMAIN}_ecc/fullchain.cer" ]]; then
    RAW_CERT="/root/.acme.sh/${HY2_DOMAIN}_ecc/fullchain.cer"
    RAW_KEY="/root/.acme.sh/${HY2_DOMAIN}_ecc/${HY2_DOMAIN}.key"
    CERT_FOUND=true
    echo "[INFO] Found acme.sh ECC certificate."
fi

# Check acme.sh (rsa) — need to copy out of /root/ for hysteria user
if [[ "${CERT_FOUND}" == "false" && -f "/root/.acme.sh/${HY2_DOMAIN}/fullchain.cer" ]]; then
    RAW_CERT="/root/.acme.sh/${HY2_DOMAIN}/fullchain.cer"
    RAW_KEY="/root/.acme.sh/${HY2_DOMAIN}/${HY2_DOMAIN}.key"
    CERT_FOUND=true
    echo "[INFO] Found acme.sh RSA certificate."
fi

# Prepare cert directory
mkdir -p /etc/hysteria/certs

if [[ "${CERT_FOUND}" == "true" ]]; then
    # Copy certs to hysteria-accessible location and fix ownership
    cp "${RAW_CERT}" "/etc/hysteria/certs/${HY2_DOMAIN}.crt"
    cp "${RAW_KEY}" "/etc/hysteria/certs/${HY2_DOMAIN}.key"
    chmod 644 "/etc/hysteria/certs/${HY2_DOMAIN}.crt"
    chmod 600 "/etc/hysteria/certs/${HY2_DOMAIN}.key"
    # Make files readable by hysteria user/group
    if id hysteria &>/dev/null; then
        chown hysteria:hysteria "/etc/hysteria/certs/${HY2_DOMAIN}.crt" "/etc/hysteria/certs/${HY2_DOMAIN}.key" 2>/dev/null || true
    fi
    HY2_CERT="/etc/hysteria/certs/${HY2_DOMAIN}.crt"
    HY2_KEY="/etc/hysteria/certs/${HY2_DOMAIN}.key"
    TEMPLATE="${PROJECT_DIR}/templates/server.tls.yaml.tpl"
    echo "[INFO] Using TLS mode with real certificate."
else
    # Generate self-signed cert
    echo "[WARN] No existing certificate found. Generating self-signed certificate."
    openssl req -x509 -nodes -days 365 \
        -newkey ec:<(openssl ecparam -name prime256v1) \
        -keyout "/etc/hysteria/certs/${HY2_DOMAIN}.key" \
        -out "/etc/hysteria/certs/${HY2_DOMAIN}.crt" \
        -subj "/CN=${HY2_DOMAIN}" 2>/dev/null
    chmod 600 "/etc/hysteria/certs/${HY2_DOMAIN}.key"
    chmod 644 "/etc/hysteria/certs/${HY2_DOMAIN}.crt"
    if id hysteria &>/dev/null; then
        chown hysteria:hysteria "/etc/hysteria/certs/${HY2_DOMAIN}.crt" "/etc/hysteria/certs/${HY2_DOMAIN}.key" 2>/dev/null || true
    fi
    HY2_CERT="/etc/hysteria/certs/${HY2_DOMAIN}.crt"
    HY2_KEY="/etc/hysteria/certs/${HY2_DOMAIN}.key"
    TEMPLATE="${PROJECT_DIR}/templates/server.selfsigned.yaml.tpl"
    echo "[INFO] Using self-signed cert mode."
fi

# Render config
mkdir -p /etc/hysteria
export HY2_CERT HY2_KEY HY2_DOMAIN HY2_PORT HY2_USER HY2_AUTH_PASSWORD
export HY2_OBFS_PASSWORD HY2_TRAFFIC_SECRET HY2_MASQUERADE_URL
export HY2_BANDWIDTH_UP HY2_BANDWIDTH_DOWN

# Simple envsubst replacement
CONFIG=$(cat "${TEMPLATE}")
CONFIG="${CONFIG//\$\{HY2_PORT\}/$HY2_PORT}"
CONFIG="${CONFIG//\$\{HY2_CERT\}/$HY2_CERT}"
CONFIG="${CONFIG//\$\{HY2_KEY\}/$HY2_KEY}"
CONFIG="${CONFIG//\$\{HY2_DOMAIN\}/$HY2_DOMAIN}"
CONFIG="${CONFIG//\$\{HY2_USER\}/$HY2_USER}"
CONFIG="${CONFIG//\$\{HY2_AUTH_PASSWORD\}/$HY2_AUTH_PASSWORD}"
CONFIG="${CONFIG//\$\{HY2_OBFS_PASSWORD\}/$HY2_OBFS_PASSWORD}"
CONFIG="${CONFIG//\$\{HY2_TRAFFIC_SECRET\}/$HY2_TRAFFIC_SECRET}"
CONFIG="${CONFIG//\$\{HY2_MASQUERADE_URL\}/$HY2_MASQUERADE_URL}"
CONFIG="${CONFIG//\$\{HY2_BANDWIDTH_UP\}/$HY2_BANDWIDTH_UP}"
CONFIG="${CONFIG//\$\{HY2_BANDWIDTH_DOWN\}/$HY2_BANDWIDTH_DOWN}"

echo "${CONFIG}" > /etc/hysteria/config.yaml
chmod 644 /etc/hysteria/config.yaml

echo "[PASS] Server config written to /etc/hysteria/config.yaml"
echo "[INFO] Certificate mode: ${CERT_FOUND:+real-cert}${CERT_FOUND:-self-signed}"
