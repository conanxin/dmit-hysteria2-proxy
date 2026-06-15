# DMIT VPS: 3X-UI & Hysteria 2 Coexistence

## Why They Can Coexist

3X-UI (Xray Reality) and Hysteria 2 can run side-by-side on the same VPS because:

1. **Different protocols on the same port number**
   - 3X-UI / Xray Reality uses **TCP 443**
   - Hysteria 2 uses **UDP 443**
   - TCP and UDP are separate transport protocols — port numbers are independent namespaces
   - Linux allows both to bind to port 443 simultaneously as long as one uses TCP and the other uses UDP

2. **Independent process management**
   - 3X-UI runs via `x-ui.service` (systemd)
   - Hysteria 2 runs via `hysteria-server.service` (systemd)
   - Zero shared configuration, zero shared state

3. **No routing conflicts**
   - 3X-UI Reality uses VLESS + Reality (XTLS) on TCP
   - Hysteria 2 uses QUIC (HTTP/3-based) on UDP
   - The protocols are completely different — no interference

## Constraints

### DO NOT:
- Run two Hysteria 2 services both on UDP 443
- Run two QUIC/HTTP3 services both on UDP 443
- Modify 3X-UI Reality inbound while Hysteria 2 is running on the same port

### OK to:
- Share the same DOMAIN for both services (DNS can resolve for both TCP & UDP)
- Use the same TLS certificate
- Run trafficStats on localhost (127.0.0.1:9999)
- Add more inbounds to 3X-UI (as long as they don't use UDP 443)

## Service Architecture

```
DMIT VPS (154.17.0.147)
├── x-ui.service
│   ├── x-ui panel: TCP 42873 (public)
│   ├── x-ui panel internal: TCP 127.0.0.1:2096
│   └── xray (managed by x-ui)
│       ├── Reality inbound: TCP 443
│       └── (other inbounds as configured)
│
├── nginx.service
│   └── HTTP: TCP 80
│
└── hysteria-server.service (NEW)
    ├── Hysteria 2: UDP 443
    └── trafficStats API: TCP 127.0.0.1:9999
```

## How This Project Handles Coexistence

- `install-hysteria2-server.sh` checks port occupancy before deployment
- TCP 443 being occupied is treated as **normal** (expected from Reality)
- UDP 443 being occupied is treated as a **blocking error**
- The script never touches x-ui, xray, or nginx services
- All Hysteria 2 config is in `/etc/hysteria/` — separate from 3X-UI

## Uninstalling

Running `uninstall-hysteria2-server.sh` will:
- Stop and disable `hysteria-server.service`
- Remove `/etc/hysteria/` configuration
- Remove the hysteria binary

It will **NOT** touch 3X-UI, xray, nginx, or any TCP port.

## Troubleshooting

### "UDP 443 already occupied"
- Check: `ss -ulnp | grep ':443'`
- Identify the process and decide whether to stop it
- If it's another Hysteria 2 instance, stop/disable it first

### "hysteria-server won't start"
- Check logs: `journalctl -u hysteria-server -e --no-pager`
- Verify config: `cat /etc/hysteria/config.yaml`
- Check port: `ss -ulnp | grep ':443'`
- Ensure the domain resolves to the VPS IP

### "3X-UI panel is down"
- Hysteria 2 deployment does NOT touch 3X-UI
- Check: `systemctl status x-ui --no-pager`
- This is likely unrelated to Hysteria 2 deployment
