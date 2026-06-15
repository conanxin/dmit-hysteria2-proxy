#!/usr/bin/env bash
# install-hysteria2-server.sh — Deploy Hysteria 2 server alongside existing 3X-UI
# Usage: sudo HY2_DOMAIN=sub.example.com ./install-hysteria2-server.sh
#
# This script:
#  - Preserves existing 3X-UI / Xray Reality on TCP 443
#  - Installs official Hysteria 2 on UDP 443
#  - Does NOT restart or modify x-ui/xray/nginx
#  - Generates client info at /root/hysteria2-client-info.txt (chmod 600)
set -euo pipefail

# ============================================================
# Configuration (env vars or defaults)
# ============================================================
HY2_DOMAIN="${HY2_DOMAIN:-}"
HY2_PORT="${HY2_PORT:-443}"
HY2_USER="${HY2_USER:-conan-main}"
HY2_AUTH_PASSWORD="${HY2_AUTH_PASSWORD:-}"
HY2_OBFS_PASSWORD="${HY2_OBFS_PASSWORD:-}"
HY2_TRAFFIC_SECRET="${HY2_TRAFFIC_SECRET:-}"
HY2_MASQUERADE_URL="${HY2_MASQUERADE_URL:-https://www.apple.com/}"
HY2_BANDWIDTH_UP="${HY2_BANDWIDTH_UP:-100 mbps}"
HY2_BANDWIDTH_DOWN="${HY2_BANDWIDTH_DOWN:-100 mbps}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"

log_info()  { echo "[INFO]  $*"; }
log_warn()  { echo "[WARN]  $*"; }
log_pass()  { echo "[PASS]  $*"; }
log_fail()  { echo "[FAIL]  $*"; }

# ============================================================
# Step 1: Root check
# ============================================================
echo "============================================"
echo " Hysteria 2 Server Installer"
echo " DMIT VPS — Coexist with 3X-UI / Xray Reality"
echo "============================================"
echo ""

if [[ $EUID -ne 0 ]]; then
    log_fail "This script must be run as root."
    exit 1
fi
log_pass "Running as root."

# ============================================================
# Step 2: System checks
# ============================================================
log_info "Checking system..."

ARCH=$(uname -m)
if [[ "${ARCH}" != "x86_64" && "${ARCH}" != "aarch64" ]]; then
    log_fail "Unsupported architecture: ${ARCH}"
    exit 1
fi
log_pass "Architecture: ${ARCH}"

if ! command -v systemctl &>/dev/null; then
    log_fail "systemd not found."
    exit 1
fi
log_pass "systemd available."

# ============================================================
# Step 3: Validate HY2_DOMAIN
# ============================================================
if [[ -z "${HY2_DOMAIN}" ]]; then
    log_fail "HY2_DOMAIN is required. Set it via environment variable."
    echo "Usage: sudo HY2_DOMAIN=sub.example.com ./install-hysteria2-server.sh"
    exit 1
fi
log_info "Domain: ${HY2_DOMAIN}"

# ============================================================
# Step 4: Port checks
# ============================================================
log_info "Checking port availability..."

# TCP 443 — expect it to be occupied by xray
if ss -tlnp 2>/dev/null | grep -q ':443\b'; then
    TCP_443_PROC=$(ss -tlnp 2>/dev/null | grep ':443\b' | awk '{print $NF}')
    log_info "TCP 443 occupied by: ${TCP_443_PROC}"
    log_info "This is expected — Hysteria 2 will use UDP 443 only."
else
    log_warn "TCP 443 is NOT occupied. Is Reality running?"
fi

# UDP 443 — must be free
if ss -ulnp 2>/dev/null | grep -q ':443\b'; then
    UDP_443_PROC=$(ss -ulnp 2>/dev/null | grep ':443\b' | awk '{print $NF}')
    log_fail "UDP 443 is already occupied by: ${UDP_443_PROC}"
    log_fail "Cannot deploy Hysteria 2 — port conflict on UDP 443."
    log_fail "Stop the conflicting service and retry."
    exit 1
fi
log_pass "UDP 443 is available for Hysteria 2."

# ============================================================
# Step 5: Install dependencies
# ============================================================
log_info "Installing dependencies..."
apt update -qq
apt install -y -qq curl ca-certificates openssl jq
log_pass "Dependencies installed."

# ============================================================
# Step 6: Install Hysteria 2
# ============================================================
log_info "Installing Hysteria 2..."

if command -v hysteria &>/dev/null; then
    HY2_CURRENT_VER=$(hysteria version 2>/dev/null | head -1 || echo "unknown")
    log_info "Hysteria already installed: ${HY2_CURRENT_VER}"
    log_info "Running official upgrade script..."
fi

# Official install/upgrade script
bash <(curl -fsSL https://get.hy2.sh/) 2>&1 | while IFS= read -r line; do
    echo "  ${line}"
done

if ! command -v hysteria &>/dev/null; then
    log_fail "Hysteria installation failed."
    exit 1
fi

HY2_VERSION=$(hysteria version 2>/dev/null | head -1 || echo "unknown")
log_pass "Hysteria installed: ${HY2_VERSION}"

# ============================================================
# Step 7: Generate random credentials if not provided
# ============================================================
log_info "Preparing credentials..."

if [[ -z "${HY2_AUTH_PASSWORD}" ]]; then
    HY2_AUTH_PASSWORD=$(openssl rand -base64 32)
    log_info "Generated random auth password."
fi

if [[ -z "${HY2_OBFS_PASSWORD}" ]]; then
    HY2_OBFS_PASSWORD=$(openssl rand -base64 32)
    log_info "Generated random obfs password."
fi

if [[ -z "${HY2_TRAFFIC_SECRET}" ]]; then
    HY2_TRAFFIC_SECRET=$(openssl rand -base64 32)
    log_info "Generated random traffic secret."
fi

# Export all vars for sub-scripts
export HY2_DOMAIN HY2_PORT HY2_USER HY2_AUTH_PASSWORD
export HY2_OBFS_PASSWORD HY2_TRAFFIC_SECRET HY2_MASQUERADE_URL
export HY2_BANDWIDTH_UP HY2_BANDWIDTH_DOWN

# ============================================================
# Step 8: Render server config
# ============================================================
log_info "Rendering server configuration..."

# Detect if real cert was found (HY2_INSECURE=0) or self-signed (HY2_INSECURE=1)
# This is determined inside render-server-config.sh
CERT_FOUND=false
for cert_path in \
    "/etc/letsencrypt/live/${HY2_DOMAIN}/fullchain.pem" \
    "/root/.acme.sh/${HY2_DOMAIN}_ecc/fullchain.cer" \
    "/root/.acme.sh/${HY2_DOMAIN}/fullchain.cer"; do
    if [[ -f "${cert_path}" ]]; then
        CERT_FOUND=true
        break
    fi
done

if [[ "${CERT_FOUND}" == "true" ]]; then
    export HY2_INSECURE="0"
    log_info "Real certificate detected — using TLS mode (insecure=0)."
else
    export HY2_INSECURE="1"
    log_info "No real certificate found — using self-signed mode (insecure=1)."
    log_warn "Self-signed mode works but clients must use insecure=1."
    log_info "To switch to real cert later: obtain cert via acme.sh and re-run this script."
fi

bash "${PROJECT_DIR}/scripts/render-server-config.sh"

# ============================================================
# Step 9: Firewall
# ============================================================
log_info "Checking firewall..."

if command -v ufw &>/dev/null && ufw status 2>/dev/null | grep -q 'Status: active'; then
    log_info "UFW is active — adding UDP 443 rule."
    ufw allow 443/udp comment 'Hysteria 2' || true
    log_info "UFW UDP 443 opened."
    log_info "NOTE: TCP 443 rules are NOT modified."
else
    log_info "UFW not active or not installed — skipping firewall."
fi

# ============================================================
# Step 10: Start service
# ============================================================
log_info "Starting Hysteria 2 service..."

systemctl daemon-reload
systemctl enable --now hysteria-server.service
systemctl restart hysteria-server.service

# Wait for service
sleep 2

# ============================================================
# Step 11: Verification
# ============================================================
log_info "Running verification..."

# 11a. Service status
if systemctl is-active --quiet hysteria-server.service; then
    log_pass "hysteria-server.service is ACTIVE."
else
    log_fail "hysteria-server.service failed to start."
    echo ""
    echo "Last 20 log lines:"
    journalctl -u hysteria-server --no-pager -n 20 2>/dev/null || true
    exit 1
fi

# 11b. UDP 443 listener
if ss -ulnp 2>/dev/null | grep -q ':443\b'; then
    UDP_PROC=$(ss -ulnp 2>/dev/null | grep ':443\b' | awk '{print $NF}')
    log_pass "UDP 443 is listening: ${UDP_PROC}"
else
    log_fail "UDP 443 is NOT listening after service start."
    exit 1
fi

# 11c. trafficStats API
sleep 1
ONLINE=$(curl -s -H "Authorization: ${HY2_TRAFFIC_SECRET}" http://127.0.0.1:9999/online 2>/dev/null || echo "ERROR")
TRAFFIC=$(curl -s -H "Authorization: ${HY2_TRAFFIC_SECRET}" http://127.0.0.1:9999/traffic 2>/dev/null || echo "ERROR")
log_info "trafficStats online: ${ONLINE}"
log_info "trafficStats traffic: ${TRAFFIC}"

# 11d. Verify x-ui still active
if systemctl is-active --quiet x-ui.service 2>/dev/null; then
    log_pass "x-ui.service is still ACTIVE — coexistence confirmed."
else
    log_warn "x-ui.service status unknown — please verify manually."
fi

# ============================================================
# Step 12: Generate client info
# ============================================================
log_info "Generating client info..."

bash "${PROJECT_DIR}/scripts/render-client-info.sh"

# ============================================================
# Step 13: Summary
# ============================================================
echo ""
echo "============================================"
echo " Hysteria 2 Deployment Complete!"
echo "============================================"
echo ""
echo "  Domain:       ${HY2_DOMAIN}"
echo "  Port:         UDP ${HY2_PORT}"
echo "  User:         ${HY2_USER}"
echo "  Cert mode:    ${CERT_FOUND:+real-cert}${CERT_FOUND:-self-signed}"
echo "  Client info:  /root/hysteria2-client-info.txt"
echo ""
echo "  3X-UI / Xray Reality: UNCHANGED (TCP 443)"
echo ""
echo "  View client info:"
echo "    sudo cat /root/hysteria2-client-info.txt"
echo ""
echo "  Health check:"
echo "    ${PROJECT_DIR}/scripts/healthcheck.sh"
echo ""
echo "============================================"
