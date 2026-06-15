# dmit-hysteria2-proxy

Open-source Hysteria 2 deployment toolkit for a DMIT VPS coexisting with 3X-UI / Xray Reality.

## What is this?

This project provides scripts, config templates, and documentation to deploy the official [Hysteria 2](https://github.com/apernet/hysteria) server on a DMIT VPS, running side-by-side with an existing **3X-UI / Xray Reality** setup without disruption.

## Why not put Hysteria 2 inside 3X-UI?

- The existing 3X-UI / Xray Reality serves as the **primary stable node** on **TCP 443**.
- Running Hysteria 2 as an independent systemd service on **UDP 443** reduces coupling and avoids breaking the production Reality node.
- 3X-UI's built-in Hysteria 2 support is less mature and may introduce instability when sharing the panel with the Reality inbound.

## Recommended Architecture

```
┌─────────────────────────────────────────────┐
│               DMIT VPS                       │
│                                               │
│  ┌─────────────┐   ┌──────────────────────┐  │
│  │   3X-UI     │   │  Hysteria 2 (systemd) │  │
│  │  Xray Reality│   │  Official binary     │  │
│  │  TCP 443    │   │  UDP 443             │  │
│  └─────────────┘   └──────────────────────┘  │
│                                               │
│  trafficStats API: 127.0.0.1:9999            │
└─────────────────────────────────────────────┘

Supported Clients:
- sing-box (recommended)
- Hiddify / Hiddify Next
- v2rayN (Windows)
- Shadowrocket (iOS)
- Mihomo / Clash Meta
```

## Quick Start

```bash
git clone https://github.com/conanxin/dmit-hysteria2-proxy.git
cd dmit-hysteria2-proxy

# Set your domain (required)
export HY2_DOMAIN=sub.conanxin.com

# Optional: set custom credentials (randomly generated if not set)
export HY2_AUTH_PASSWORD=your-strong-password
export HY2_OBFS_PASSWORD=your-obfs-password

# Deploy
sudo -E ./scripts/install-hysteria2-server.sh
```

After deployment, your client info will be at `/root/hysteria2-client-info.txt`.

## Security

**Real credentials NEVER enter this repository.** The `.gitignore` blocks:

- `.env` files
- `*.secret`, `*.key`, `*.pem`, `*.crt`
- `client-info.txt`, `share-link.txt`, `actual-config.yaml`
- `reports/*_PRIVATE*.md`

Credentials are generated locally on the VPS and stored only in `/root/hysteria2-client-info.txt` (chmod 600).

## Project Structure

```
.
├── README.md
├── LICENSE
├── .gitignore
├── .env.example
├── scripts/
│   ├── preflight.sh                  # Pre-flight environment check
│   ├── install-hysteria2-server.sh   # Main deployment script
│   ├── render-server-config.sh       # Config template renderer
│   ├── render-client-info.sh         # Client info generator
│   ├── healthcheck.sh                # Service health check
│   └── uninstall-hysteria2-server.sh # Graceful removal
├── templates/
│   ├── server.tls.yaml.tpl           # Server config with real TLS cert
│   ├── server.selfsigned.yaml.tpl    # Server config with self-signed cert
│   ├── client.official.yaml.tpl      # Official Hysteria 2 client config
│   ├── client.sing-box-outbound.json.tpl
│   └── client.mihomo.yaml.tpl
├── docs/
│   ├── DMIT_3XUI_COEXISTENCE.md
│   ├── CLIENT_USAGE.md
│   ├── OPERATIONS.md
│   ├── TROUBLESHOOTING.md
│   └── DESIGN_NOTES.md
└── reports/
    └── .gitkeep
```

## License

MIT — see [LICENSE](./LICENSE).
