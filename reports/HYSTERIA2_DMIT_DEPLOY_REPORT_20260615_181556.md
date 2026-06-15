# Hysteria 2 DMIT VPS Deployment Report

**Report:** HYSTERIA2_DMIT_DEPLOY_REPORT_20260615_181556
**Date:** 2026-06-15 18:15 CST (10:15 UTC)
**Project:** DMIT-HY2-OPEN-1

---

## Overall Status: ✅ PASS

All deployment objectives achieved. Hysteria 2 is running alongside existing 3X-UI / Xray Reality without conflict.

---

## 1. VPS Information

| Item | Value |
|------|-------|
| IP Address | 154.17.0.147 |
| OS | Ubuntu 24.04.4 LTS |
| Architecture | x86_64 |
| Virtualization | KVM |
| Kernel | 6.8.0-35-generic |

---

## 2. Hysteria 2 Status

| Item | Value |
|------|-------|
| Version | v2.9.2 |
| Service | `hysteria-server.service` — **active (running)** |
| Protocol | UDP 443 |
| Process PID | 444880 |
| Config path | `/etc/hysteria/config.yaml` |
| Client info | `/root/hysteria2-client-info.txt` (chmod 600) |

---

## 3. 3X-UI / Xray Reality Status

| Item | Value |
|------|-------|
| Service | `x-ui.service` — **active (running)** |
| Protocol | TCP 443 (Xray Reality) |
| Process PID | 344947 (xray) |
| Impact from H2 deploy | **NONE** — No modification, no restart |

---

## 4. Port Listening Summary

| Port | Protocol | Service | Process |
|------|----------|---------|---------|
| TCP 443 | Xray Reality | xray-linux-amd64 | PID 344947 |
| UDP 443 | Hysteria 2 | hysteria | PID 444880 |
| TCP 127.0.0.1:9999 | trafficStats API | hysteria | PID 444880 |
| TCP 80 | HTTP | nginx | PID 8020 |
| TCP 42873 | x-ui panel | x-ui | PID 344915 |

**Coexistence confirmed:** TCP 443 (Xray) and UDP 443 (Hysteria 2) run simultaneously without conflict.

---

## 5. Certificate

| Item | Value |
|------|-------|
| Type | Real certificate (Let's Encrypt via acme.sh) |
| Domain | hy2.conanxin.com |
| Certificate path | `/etc/hysteria/certs/hy2.conanxin.com.crt` |
| Key path | `/etc/hysteria/certs/hy2.conanxin.com.key` |
| ACME location | `/root/.acme.sh/hy2.conanxin.com_ecc/` |
| Client insecure | 0 (standard TLS validation) |
| Certificate DN | CN=hy2.conanxin.com |
| Issuer | Let's Encrypt (E1) |
| Expiry | 2026-09-13 |

**Note:** Certificates are copied from `/root/.acme.sh/` to `/etc/hysteria/certs/` with `hysteria:hysteria` ownership, because the hysteria service user cannot access `/root/`.

---

## 6. trafficStats API

| Item | Value |
|------|-------|
| Listen | 127.0.0.1:9999 (localhost only) |
| Online endpoint | `GET /online` ✅ responds |
| Traffic endpoint | `GET /traffic` ✅ responds |
| Public exposure | **None** — bound to localhost only |

---

## 7. GitHub Repository

| Item | Value |
|------|-------|
| URL | https://github.com/conanxin/dmit-hysteria2-proxy |
| Branch | main |
| Latest commit | `cf86ce2` — "Fix cert permissions: copy certs to /etc/hysteria/certs/ for hysteria user access" |
| Initial commit | `4494edf` — "Initial open-source Hysteria 2 deployment toolkit for DMIT VPS" |
| License | MIT |
| Visibility | Public |
| Sensitive data in repo | **NONE** — enforced by `.gitignore` |

---

## 8. Client Information

| Item | Value |
|------|-------|
| Server | hy2.conanxin.com:443 |
| User | conan-main |
| Auth type | userpass |
| Obfs | salamander |
| TLS insecure | 0 (real cert) |
| Client info file | `/root/hysteria2-client-info.txt` |
| File permissions | 600 (root only) |

### Share Link (masked — real link in `/root/hysteria2-client-info.txt`)

```
hysteria2://conan-main:***@hy2.conanxin.com:443/?sni=hy2.conanxin.com&insecure=0&obfs=salamander&obfs-password=***#DMIT-HY2
```

---

## 9. Impact on 3X-UI / Reality

**✅ NO IMPACT.** The deployment:

- Did not stop, restart, or modify `x-ui.service`
- Did not modify any x-ui/Xray configuration
- Did not touch nginx configuration
- Did not change any TCP port rules
- Both services are running independently

---

## 10. Next Steps for You

### Immediate — Connect a Client

```bash
# On the VPS:
sudo cat /root/hysteria2-client-info.txt
```

1. Copy the `hysteria2://` share link
2. Import into your client (Hiddify / Shadowrocket / v2rayN / sing-box)
3. Enable the node and test connectivity
4. Keep Reality (TCP 443) as your primary stable node
5. Use Hysteria 2 (UDP 443) as your high-speed/backup node

### Routine Operations

```bash
# Check status
systemctl status hysteria-server --no-pager

# View logs
journalctl -u hysteria-server -e --no-pager

# Health check
cd ~/projects/dmit-hysteria2-proxy
./scripts/healthcheck.sh

# Upgrade Hysteria 2
bash <(curl -fsSL https://get.hy2.sh/)
systemctl restart hysteria-server
```

### Certificate Renewal

Let's Encrypt cert expires 2026-09-13. acme.sh auto-renews. After renewal, copy new certs:

```bash
cp /root/.acme.sh/hy2.conanxin.com_ecc/fullchain.cer /etc/hysteria/certs/hy2.conanxin.com.crt
cp /root/.acme.sh/hy2.conanxin.com_ecc/hy2.conanxin.com.key /etc/hysteria/certs/hy2.conanxin.com.key
chown hysteria:hysteria /etc/hysteria/certs/hy2.conanxin.com.*
systemctl restart hysteria-server
```

### Uninstall (if needed)

```bash
cd ~/projects/dmit-hysteria2-proxy
sudo ./scripts/uninstall-hysteria2-server.sh
```

---

## 11. Issues Encountered & Resolved

| Issue | Resolution |
|-------|------------|
| Config file permission denied for hysteria user | Changed `/etc/hysteria/config.yaml` to 644 |
| Certificate files under `/root/` inaccessible to hysteria user | Copy certs to `/etc/hysteria/certs/` with `hysteria:hysteria` ownership |
| ACME standalone mode blocked by nginx on port 80 | Used webroot mode (`-w /var/www/html`) |

---

## 12. Security Notes

- ⚠️ **x-ui panel** is exposed on TCP 42873 (public). Consider restricting via firewall or Cloudflare.
- All Hysteria 2 credentials are stored only in `/root/hysteria2-client-info.txt` (chmod 600).
- trafficStats API is bound to 127.0.0.1 only — not publicly accessible.
- No UFW/firewall installed. Consider installing UFW for additional protection.
- GitHub repo contains NO real credentials, passwords, or secrets.

---

*Report generated by WorkBuddy as part of project DMIT-HY2-OPEN-1.*
