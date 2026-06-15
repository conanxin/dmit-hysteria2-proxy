# Client Import Checklist

> **Prerequisite:** Get your real client credentials from the VPS:
> ```bash
> sudo cat /root/hysteria2-client-info.txt
> ```
>
> This file contains the `hysteria2://` share link — the fastest way to import on most clients.

---

## Quick Reference (Masked)

| Field | Value |
|-------|-------|
| Protocol | Hysteria2 |
| Server | `hy2.conanxin.com` |
| Port | `443` |
| Auth Type | userpass |
| Username | `conan-main` |
| Password | *(see `/root/hysteria2-client-info.txt`)* |
| Obfuscation | salamander |
| Obfs Password | *(see `/root/hysteria2-client-info.txt`)* |
| TLS SNI | `hy2.conanxin.com` |
| TLS Insecure | `0` (real certificate) |
| Share Link | `hysteria2://conan-main:***@hy2.conanxin.com:443/?sni=hy2.conanxin.com&insecure=0&obfs=salamander&obfs-password=***#DMIT-HY2` |

---

## 1. Hiddify / Hiddify Next

**Platforms:** iOS, Android, macOS, Windows, Linux

### Import via Share Link (Recommended)

1. Open Hiddify.
2. Tap the **+** button (bottom-right on mobile, top-left on desktop).
3. Select **Import from Clipboard**.
4. On the VPS:
   ```bash
   sudo cat /root/hysteria2-client-info.txt
   ```
5. Copy the entire `hysteria2://` line.
6. Switch back to Hiddify — paste (already in clipboard, just tap confirm).
7. ✅ Node appears as **DMIT-HY2**.

### Verify

1. Go to **Profiles** or **Proxies** tab.
2. Tap/Double-click **DMIT-HY2** to connect.
3. Open browser → visit `https://ip.sb` or `https://whatismyipaddress.com`.
4. Confirm your IP shows `154.17.0.147`.

### Troubleshooting

- **Timeout:** Check UDP 443 reachability; confirm obfs password matches.
- **Auth failed:** Double-check username (`conan-main`) and password.
- **TLS error:** Ensure `insecure` is `0` (we have a real Let's Encrypt cert on `hy2.conanxin.com`).

---

## 2. Shadowrocket

**Platforms:** iOS (App Store)

### Import via Share Link

1. Tap the **+** (top-right corner).
2. Tap **Type** → scroll down → select **Hysteria2**.
3. Tap **URL** at the top, paste the `hysteria2://` link from `/root/hysteria2-client-info.txt`.
4. Tap **Done**.
5. ✅ Node appears as **DMIT-HY2**.

### Or: Manual Entry

If the share link doesn't auto-fill correctly:

| Field | Fill In |
|-------|---------|
| Type | Hysteria2 |
| Address | `hy2.conanxin.com` |
| Port | `443` |
| Auth | Password |
| Password | *(from client-info.txt)* |
| Obfuscation | salamander |
| Obfuscation Password | *(from client-info.txt)* |
| Allow Insecure | ON (Only if self-signed) |
| SNI | `hy2.conanxin.com` |

### Verify

1. Turn on the **DMIT-HY2** node.
2. Open Safari → visit `https://ip.sb`.
3. Confirm the IP shown is your DMIT VPS.

### Known Issue

- **"Empty reply from server":** Usually obfs password mismatch. Triple-check the obfs password from `/root/hysteria2-client-info.txt`.

---

## 3. v2rayN

**Platforms:** Windows

### Import via Share Link

1. Launch v2rayN.
2. From the top menu: **Server** → **Import from Clipboard**.
3. On the VPS: `sudo cat /root/hysteria2-client-info.txt`, copy the `hysteria2://` line.
4. The node auto-appears in the server list as **DMIT-HY2**.
5. ✅ Done.

### Or: Custom Config

1. **Server** → **Add Custom Config Server**.
2. Give it an alias like `DMIT-HY2`.
3. Paste the entire **sing-box Outbound JSON** block from `/root/hysteria2-client-info.txt`.
4. If using sing-box core, check **Core Type** is set to `sing-box`.
5. Click **OK**.

### Verify

1. Right-click the system tray icon → **System Proxy** → **Set System Proxy**.
2. Select the **DMIT-HY2** node.
3. Press Enter to activate.
4. Open browser → `https://ip.sb` → should show `154.17.0.147`.

### Tips

- For best performance, pair v2rayN with the **sing-box** core (not Xray core) when using Hysteria2.
- TUN mode works if you install the sing-box TUN driver.

---

## 4. sing-box (Standalone / CLI)

**Platforms:** Linux, macOS, Windows (sing-box binary)

### Import

1. Open your sing-box `config.json`.
2. Under the `"outbounds"` array, add the JSON block from `/root/hysteria2-client-info.txt`:

   ```json
   {
     "outbounds": [
       {
         "type": "hysteria2",
         "tag": "DMIT-HY2",
         "server": "hy2.conanxin.com",
         "server_port": 443,
         "up_mbps": 20,
         "down_mbps": 100,
         "password": "<your-real-password>",
         "obfs": {
           "type": "salamander",
           "password": "<your-real-obfs-password>"
         },
         "tls": {
           "enabled": true,
           "server_name": "hy2.conanxin.com",
           "insecure": false
         }
       }
     ]
   }
   ```

3. Replace `<your-real-password>` and `<your-real-obfs-password>` with the actual values from `/root/hysteria2-client-info.txt`.
4. Restart sing-box:
   ```bash
   sing-box run -c /path/to/config.json
   ```

### Verify

```bash
curl -x socks5h://127.0.0.1:7898 https://ip.sb
```

Should return your VPS IP.

### Tips

- If using sing-box as a system service under systemd, restart with:
  ```bash
  systemctl restart sing-box
  ```
- The local SOCKS5 port depends on your sing-box inbounds config — the outbound block above is just the proxy definition.

---

## 5. Mihomo / Clash Meta

**Platforms:** All (Mihomo / Clash Verge / Clash Meta for Android)

### Import

Add the proxy block from `/root/hysteria2-client-info.txt` into your Mihomo config under `proxies`:

```yaml
proxies:
  - name: "DMIT-HY2"
    type: hysteria2
    server: hy2.conanxin.com
    port: 443
    password: "<your-real-password>"
    obfs: salamander
    obfs-password: "<your-real-obfs-password>"
    sni: hy2.conanxin.com
    skip-cert-verify: false
    up: 20
    down: 100
```

Replace `<your-real-password>` and `<your-real-obfs-password>` with the actual values.

### Verify

1. In Clash Verge or Mihomo Party, select **DMIT-HY2** as active proxy.
2. Turn on System Proxy.
3. Visit `https://ip.sb` — should show `154.17.0.147`.

---

## Universal Sanity Checks

After importing into any client, perform these checks:

- [ ] DNS resolves: `hy2.conanxin.com` → `154.17.0.147`
- [ ] UDP 443 reachable from client network
- [ ] Password and obfs password match VPS config
- [ ] TLS `insecure` set to `0` (real cert) or `1` (self-signed)
- [ ] External IP check shows DMIT VPS IP
- [ ] Existing 3X-UI / Reality node still works (TCP 443 unaffected)

---

## Emergency: If Nothing Works

1. SSH to VPS:
   ```bash
   ssh dmit-control-tower
   ```
2. Check service:
   ```bash
   systemctl status hysteria-server --no-pager
   journalctl -u hysteria-server -e --no-pager -n 50
   ```
3. Run health check:
   ```bash
   cd ~/projects/dmit-hysteria2-proxy
   ./scripts/healthcheck.sh
   ```
4. Re-read exact credentials:
   ```bash
   sudo cat /root/hysteria2-client-info.txt
   ```
5. Common fixes:
   - **Firewall blocking UDP 443** on client network (corporate/college networks)
   - **Typo in password/obfs** → compare character by character
   - **Hysteria version mismatch** → ensure client uses Hysteria2 protocol (not v1)
