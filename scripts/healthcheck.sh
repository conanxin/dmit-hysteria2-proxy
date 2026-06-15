#!/usr/bin/env bash
# healthcheck.sh — Check Hysteria 2 service health
set -euo pipefail

echo "=== Hysteria 2 Health Check ==="
echo ""

# 1. Service status
echo "[1/4] Service Status:"
if systemctl is-active --quiet hysteria-server 2>/dev/null; then
    echo "  [PASS] hysteria-server.service is active."
else
    echo "  [FAIL] hysteria-server.service is NOT active."
    exit 1
fi

# 2. UDP 443 listener
echo ""
echo "[2/4] UDP 443 Listener:"
if ss -ulnp 2>/dev/null | grep -q ':443\b'; then
    HY2_PROC=$(ss -ulnp 2>/dev/null | grep ':443\b' | awk '{print $NF}')
    echo "  [PASS] UDP 443 occupied by: ${HY2_PROC}"
else
    echo "  [FAIL] UDP 443 is NOT occupied by hysteria-server."
fi

# 3. TCP 443 (should still be xray)
echo ""
echo "[3/4] TCP 443 (Xray/Reality):"
if ss -tlnp 2>/dev/null | grep -q ':443\b'; then
    TCP_PROC=$(ss -tlnp 2>/dev/null | grep ':443\b' | awk '{print $NF}')
    echo "  [PASS] TCP 443 still occupied by: ${TCP_PROC}"
else
    echo "  [WARN] TCP 443 is NOT occupied — is Reality still running?"
fi

# 4. trafficStats API
echo ""
echo "[4/4] trafficStats API:"
if [[ -f /etc/hysteria/config.yaml ]]; then
    TRAFFIC_SECRET=$(grep 'secret:' /etc/hysteria/config.yaml | head -1 | awk '{print $2}')
    if [[ -n "${TRAFFIC_SECRET}" ]]; then
        ONLINE=$(curl -s -H "Authorization: ${TRAFFIC_SECRET}" http://127.0.0.1:9999/online 2>/dev/null || echo "ERROR")
        TRAFFIC=$(curl -s -H "Authorization: ${TRAFFIC_SECRET}" http://127.0.0.1:9999/traffic 2>/dev/null || echo "ERROR")
        echo "  Online users: ${ONLINE}"
        echo "  Traffic: ${TRAFFIC}"
    else
        echo "  [WARN] Could not read traffic secret from config."
    fi
else
    echo "  [WARN] /etc/hysteria/config.yaml not found."
fi

# 5. Check x-ui still running
echo ""
echo "[INFO] 3X-UI coexistence check:"
if systemctl is-active --quiet x-ui 2>/dev/null; then
    echo "  [PASS] x-ui.service is still active."
else
    echo "  [WARN] x-ui.service is NOT active."
fi

echo ""
echo "=== Health Check Complete ==="
