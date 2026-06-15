# Troubleshooting

## Common Issues

### Connection timeout / no response

**Causes:**
1. UDP 443 blocked by firewall (VPS or client network)
2. Domain DNS not pointing to VPS
3. Obfuscation password mismatch

**Diagnosis:**
```bash
# On VPS: check if hysteria is listening on UDP 443
ss -ulnp | grep ':443'

# Check if service is actually running
systemctl status hysteria-server --no-pager

# Check traffic (any connections at all?)
curl -H "Authorization: <secret>" http://127.0.0.1:9999/online
```

**Fixes:**
- Ensure client obfs password matches server
- Verify `insecure=1` if using self-signed cert
- Test from a different network

### Authentication failed

**Causes:**
- Wrong username or password in client config
- Client using wrong auth type

**Fix:**
```bash
# Re-check credentials on VPS
sudo cat /root/hysteria2-client-info.txt
```
Verify client is using `userpass` auth with the exact username:password pair.

### TLS handshake error

**Causes:**
- Certificate not valid for the domain
- Client `insecure` setting wrong
- Domain mismatch between SNI and certificate CN/SAN

**Fix:**
- If self-signed: set `insecure: 1` in client config
- If real cert: set `insecure: 0`
- Verify domain resolves correctly: `dig +short your-domain.com`

### Connection is slow

**Causes:**
- Bandwidth limits set too low
- VPS network congestion
- Client network conditions

**Fix:**
1. Adjust bandwidth limits in `/etc/hysteria/config.yaml`:
   ```yaml
   bandwidth:
     up: 500 mbps
     down: 500 mbps
   ```
2. Restart: `systemctl restart hysteria-server`
3. Test with Reality node to compare — if both are slow, it's network/server-side

### Telegram / API not working through proxy

Verify the app is actually using the proxy port:
- The default local proxy is `127.0.0.1:7898` (SOCKS5) or `127.0.0.1:7899` (HTTP)
- Check your app's proxy settings

### hysteria-server won't start after config change

```bash
# Check syntax
cat /etc/hysteria/config.yaml

# View error logs
journalctl -u hysteria-server -e --no-pager -n 50

# Common config issues:
# - YAML indentation errors
# - Missing or malformed auth section
# - Certificate files don't exist or wrong permissions
```

### 3X-UI / Reality affected?

**Hysteria 2 deployment should NEVER affect 3X-UI.**

If Reality stops working:
```bash
systemctl status x-ui --no-pager
journalctl -u x-ui -e --no-pager
```

This is almost certainly caused by something else. Check:
- Did you manually change any config?
- Is the VPS running out of resources?
- Did the VPS provider change anything?

Revert Hysteria 2 if needed:
```bash
systemctl stop hysteria-server  # This stops only Hysteria 2
```
