# Operations Guide

## Daily Operations

### Check service status
```bash
systemctl status hysteria-server --no-pager
```

### View recent logs
```bash
journalctl -u hysteria-server -e --no-pager
```

Real-time logs:
```bash
journalctl -u hysteria-server -f
```

### Health check
```bash
./scripts/healthcheck.sh
```

Checks:
- Service active status
- UDP 443 listener
- TCP 443 (Reality) still active
- trafficStats API responsiveness
- 3X-UI coexistence

### View client info
```bash
sudo cat /root/hysteria2-client-info.txt
```

### trafficStats API queries
```bash
# Get traffic secret from config
TRAFFIC_SECRET=$(grep 'secret:' /etc/hysteria/config.yaml | head -1 | awk '{print $2}')

# Check online users
curl -H "Authorization: ${TRAFFIC_SECRET}" http://127.0.0.1:9999/online

# Check traffic stats
curl -H "Authorization: ${TRAFFIC_SECRET}" http://127.0.0.1:9999/traffic
```

## Service Management

### Restart Hysteria 2
```bash
systemctl restart hysteria-server
```

### Stop Hysteria 2 (without uninstalling)
```bash
systemctl stop hysteria-server
```

### Start Hysteria 2
```bash
systemctl start hysteria-server
```

## Upgrading Hysteria 2

```bash
bash <(curl -fsSL https://get.hy2.sh/)
systemctl restart hysteria-server
systemctl status hysteria-server --no-pager
```

The upgrade preserves `/etc/hysteria/config.yaml`.

## Changing Configuration

1. Edit `/etc/hysteria/config.yaml`
2. Restart: `systemctl restart hysteria-server`
3. Verify: `systemctl status hysteria-server --no-pager`

### Add a new user
1. Edit `/etc/hysteria/config.yaml`
2. Under `auth.userpass`, add a new line: `  newuser: <password>`
3. Restart service

## Uninstalling

```bash
sudo ./scripts/uninstall-hysteria2-server.sh
```

This removes:
- Hysteria 2 binary
- `/etc/hysteria/` configuration
- `hysteria-server.service` systemd unit
- `/root/hysteria2-client-info.txt`

It does NOT touch:
- 3X-UI / Xray Reality
- nginx
- Any TCP port rules
- Firewall rules (you may need to remove UDP 443 rule manually)

## Firewall

If using UFW:
```bash
# Check current rules
ufw status

# Remove Hysteria 2 rule (if needed)
ufw delete allow 443/udp
```

## Certificate Renewal

If using Let's Encrypt or acme.sh, certificates auto-renew. After renewal:

```bash
systemctl restart hysteria-server
```

The restart is needed to load the new certificate. Consider adding a post-renewal hook in your acme.sh config.
