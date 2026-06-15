# Design Notes

## Why This Project Exists

The DMIT VPS runs a stable 3X-UI + Xray Reality setup on TCP 443 as the primary production node. We need a second protocol for speed/redundancy without disrupting the working Reality node.

Hysteria 2 was chosen because:
- QUIC-based, designed for speed and lossy networks
- Official standalone binary with systemd integration
- Mature ecosystem support (sing-box, Hiddify, Shadowrocket, v2rayN, Mihomo)
- Salamander obfuscation for traffic disguise

## Design Decisions

### 1. Independent systemd service (not inside 3X-UI)

**Decision:** Run Hysteria 2 as a standalone systemd service outside 3X-UI.

**Rationale:**
- The existing Reality node is production-stable. Integrating H2 into 3X-UI risks panel-level conflicts.
- 3X-UI's Hysteria 2 implementation is less battle-tested than the official binary.
- Independent services = independent failure domains. If H2 crashes, Reality keeps running.
- Easier to upgrade H2 via official script without touching 3X-UI.

### 2. UDP 443 (same port as Reality TCP 443)

**Decision:** Use UDP 443 alongside Reality's TCP 443.

**Rationale:**
- Port 443 is the universal "open" port — rarely blocked by firewalls.
- TCP and UDP are separate transport namespaces — no conflict.
- Clients only need to know one port number.
- Masquerade as regular HTTPS traffic on the same port.

### 3. Userpass auth (not HTTP basic)

**Decision:** Use `auth.type: userpass` with base64-encoded credentials.

**Rationale:**
- Official Hysteria 2 support for per-user configuration.
- Compatible with all major clients.
- Easier credential management than inline HTTP basic.

### 4. Salamander obfuscation

**Decision:** Enable `obfs.type: salamander` with strong random password.

**Rationale:**
- Adds a layer of obfuscation beyond QUIC's native encryption.
- Salamander is the recommended obfuscation method for Hysteria 2.
- Makes traffic patterns harder to fingerprint.

### 5. Masquerade as proxy to apple.com

**Decision:** Default masquerade target is `https://www.apple.com/`.

**Rationale:**
- apple.com is a high-traffic CDN domain — innocent-looking.
- "Proxy" masquerade mode forwards unrecognized traffic to the target.
- HTTP 443 responses look like normal Apple CDN traffic.

### 6. Open-source repo, private credentials

**Decision:** Public GitHub repo with deployment tools only. Real credentials never committed.

**Rationale:**
- The deployment toolkit is reusable and useful for the community.
- No sensitive data in the repo — enforced by `.gitignore`.
- Credentials live only on the VPS (`/root/hysteria2-client-info.txt`, chmod 600).

### 7. trafficStats on localhost only

**Decision:** Bind trafficStats to 127.0.0.1:9999, not public.

**Rationale:**
- trafficStats exposes usage data — should not be publicly accessible.
- Can be queried locally or tunneled through SSH.
- Future integration with Conan VPS Control Tower via local access.

### 8. Self-signed cert as fallback

**Decision:** If no real certificate exists, generate a self-signed cert and mark `insecure=1`.

**Rationale:**
- Allows immediate deployment without waiting for DNS + cert issuance.
- Self-signed certs are fully functional for encrypted QUIC tunnels.
- Users are clearly informed and can switch to real cert later.
- The `insecure` flag is encoded in the share link automatically.

## Future Improvements

- [ ] ACME cert auto-issuance integrated into install script
- [ ] Multi-user management script
- [ ] Monitoring dashboard (Grafana + trafficStats)
- [ ] Auto-upgrade cron job
- [ ] Integration with Conan VPS Control Tower
- [ ] Docker-based deployment option
