# Client Usage Guide

## Getting Your Client Info

After deployment, all client credentials are in:

```bash
sudo cat /root/hysteria2-client-info.txt
```

This file contains:
- Share link (`hysteria2://...`)
- Official client YAML config
- sing-box outbound JSON
- Mihomo proxy YAML

## Mobile Clients (QR Code / Share Link)

### Hiddify / Hiddify Next (iOS / Android)
1. Open app, tap "+" to add profile
2. Select "Import from Clipboard"
3. Copy the `hysteria2://` share link from `/root/hysteria2-client-info.txt`
4. Paste and confirm

### Shadowrocket (iOS)
1. Tap "+" → Type: Hysteria2
2. Fill in server, port (443), password, obfs=salamander, obfs password
3. Or paste the share link directly

### v2rayN (Windows)
1. Server → "Share Link Import"
2. Paste the `hysteria2://` link
3. Or manually configure: Server → Add → Hysteria2

## Desktop Clients (YAML Config)

### Official Hysteria 2 Client
Save the "Official Client YAML" section from `/root/hysteria2-client-info.txt` as `config.yaml`:

```bash
hysteria -c config.yaml
```

Local proxy ports:
- SOCKS5: `127.0.0.1:7898`
- HTTP: `127.0.0.1:7899`

### sing-box
Save the "sing-box Outbound JSON" section into your sing-box `config.json` under `outbounds` array:

```json
{
  "outbounds": [
    ...existing outbounds...,
    { ... paste the hysteria2 outbound here ... }
  ]
}
```

### Mihomo / Clash Meta
Save the "Mihomo Proxy YAML" section into your Mihomo config under `proxies`:

```yaml
proxies:
  ...existing proxies...,
  - name: "DMIT-HY2"
    ... paste the hysteria2 proxy here ...
```

## Connection Test

After importing:
1. Enable the Hysteria 2 node as your active proxy
2. Test with `curl -x socks5h://127.0.0.1:7898 https://ip.sb` or similar
3. Confirm the IP shown is your DMIT VPS (154.17.0.147)

## Bandwidth Tuning

Default client bandwidth:
- Upload: 20 mbps
- Download: 100 mbps

Adjust in the client config if your connection supports more. For mobile clients, lower values save battery.

## TLS Certificate Notes

### If using real certificate (insecure=0)
No special client configuration needed. Standard TLS validation.

### If using self-signed certificate (insecure=1)
Clients must be configured to skip certificate verification. The share link includes `insecure=1` automatically.

To switch from self-signed to real certificate later:
1. Obtain a real certificate (acme.sh recommended)
2. Re-run `install-hysteria2-server.sh` — it will auto-detect the cert
3. Update client configs to `insecure=0`
