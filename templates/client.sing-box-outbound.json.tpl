{
  "type": "hysteria2",
  "tag": "DMIT-HY2",
  "server": "${HY2_DOMAIN}",
  "server_port": ${HY2_PORT},
  "up_mbps": 20,
  "down_mbps": 100,
  "password": "${HY2_AUTH_PASSWORD}",
  "obfs": {
    "type": "salamander",
    "password": "${HY2_OBFS_PASSWORD}"
  },
  "tls": {
    "enabled": true,
    "server_name": "${HY2_DOMAIN}",
    "insecure": ${HY2_INSECURE}
  }
}
