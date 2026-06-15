#!/usr/bin/env bash
# render-client-info.sh — Generate Hysteria 2 client info and share link
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"

HY2_DOMAIN="${HY2_DOMAIN:-}"
HY2_PORT="${HY2_PORT:-443}"
HY2_USER="${HY2_USER:-conan-main}"
HY2_AUTH_PASSWORD="${HY2_AUTH_PASSWORD:-}"
HY2_OBFS_PASSWORD="${HY2_OBFS_PASSWORD:-}"
HY2_TRAFFIC_SECRET="${HY2_TRAFFIC_SECRET:-}"
HY2_INSECURE="${HY2_INSECURE:-0}"

if [[ "${HY2_INSECURE}" == "1" ]]; then
    HY2_INSECURE_BOOL="true"
else
    HY2_INSECURE_BOOL="false"
fi

echo "=== Generating Client Info ==="

# Check required vars
if [[ -z "${HY2_DOMAIN}" ]]; then
    echo "[FAIL] HY2_DOMAIN is required."
    exit 1
fi
if [[ -z "${HY2_AUTH_PASSWORD}" ]]; then
    echo "[FAIL] HY2_AUTH_PASSWORD is required."
    exit 1
fi

# Generate share link
URL_ENCODED_USER=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${HY2_USER}'))" 2>/dev/null || echo "${HY2_USER}")
URL_ENCODED_PASS=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${HY2_AUTH_PASSWORD}'))" 2>/dev/null || echo "${HY2_AUTH_PASSWORD}")
URL_ENCODED_OBFS=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${HY2_OBFS_PASSWORD}'))" 2>/dev/null || echo "${HY2_OBFS_PASSWORD}")
SHARE_LINK="hysteria2://${URL_ENCODED_USER}:${URL_ENCODED_PASS}@${HY2_DOMAIN}:${HY2_PORT}/?sni=${HY2_DOMAIN}&insecure=${HY2_INSECURE}&obfs=salamander&obfs-password=${URL_ENCODED_OBFS}#DMIT-HY2"

# Render official client config
render_template() {
    local tpl="$1"
    local out="$2"
    if [[ -f "${tpl}" ]]; then
        sed \
            -e "s|\${HY2_DOMAIN}|${HY2_DOMAIN}|g" \
            -e "s|\${HY2_PORT}|${HY2_PORT}|g" \
            -e "s|\${HY2_USER}|${HY2_USER}|g" \
            -e "s|\${HY2_AUTH_PASSWORD}|${HY2_AUTH_PASSWORD}|g" \
            -e "s|\${HY2_OBFS_PASSWORD}|${HY2_OBFS_PASSWORD}|g" \
            -e "s|\${HY2_INSECURE}|${HY2_INSECURE}|g" \
            -e "s|\${HY2_INSECURE_BOOL}|${HY2_INSECURE_BOOL}|g" \
            "${tpl}" > "${out}"
    fi
}

TMPDIR=$(mktemp -d)
render_template "${PROJECT_DIR}/templates/client.official.yaml.tpl" "${TMPDIR}/client.yaml"
render_template "${PROJECT_DIR}/templates/client.sing-box-outbound.json.tpl" "${TMPDIR}/sing-box-outbound.json"
render_template "${PROJECT_DIR}/templates/client.mihomo.yaml.tpl" "${TMPDIR}/mihomo-proxy.yaml"

# Write full client info to /root/hysteria2-client-info.txt
OUTFILE="/root/hysteria2-client-info.txt"
cat > "${OUTFILE}" << EOF
======================================================
Hysteria 2 Client Information
Generated: $(date -u)
======================================================

Server:     ${HY2_DOMAIN}:${HY2_PORT}
User:       ${HY2_USER}
Password:   ${HY2_AUTH_PASSWORD}
Obfs Type:  salamander
Obfs Pass:  ${HY2_OBFS_PASSWORD}
TLS Insecure: ${HY2_INSECURE}
Traffic Secret: ${HY2_TRAFFIC_SECRET}

--- Share Link (hysteria2://) ---
${SHARE_LINK}

--- Official Client YAML ---
$(cat "${TMPDIR}/client.yaml")

--- sing-box Outbound JSON ---
$(cat "${TMPDIR}/sing-box-outbound.json")

--- Mihomo Proxy YAML ---
$(cat "${TMPDIR}/mihomo-proxy.yaml")

======================================================
EOF

chmod 600 "${OUTFILE}"
rm -rf "${TMPDIR}"

echo "[PASS] Client info written to ${OUTFILE} (chmod 600)"
echo ""
echo "=== Client Info Generated ==="
