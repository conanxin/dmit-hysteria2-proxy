# dmit-hysteria2-proxy 中文说明

> 一个用于在已有 3X-UI / Xray Reality 的 DMIT VPS 上，并行部署官方 Hysteria 2 的开源部署工具。

[English](./README.md) | [简体中文](./README.zh-CN.md)

---

## 这个项目是什么

这是一个 **Hysteria 2 部署器**，不是一个代理面板。

**它能做什么：**
- 在已有 3X-UI / Xray Reality 的 VPS 上，新增官方 Hysteria 2 服务
- Reality 继续作为 **TCP 443 主力节点**
- Hysteria 2 使用 **UDP 443**，作为高速备用节点
- TCP 443 和 UDP 443 **可以同时存在**，互不冲突

**它不包含什么：**
- 不包含真实密码、obfs 密钥、完整分享链接
- GitHub 仓库只放脚本、模板和文档
- 真实凭证只保存在 VPS 本地的 `/root/hysteria2-client-info.txt`

---

## 为什么不直接放进 3X-UI

| 原因 | 说明 |
|------|------|
| 稳定优先 | 现有 Reality 节点已经稳定运行，不应为了新增协议去改动主力节点 |
| 降低耦合 | 3X-UI/Reality 和 Hysteria 2 分开管理，排查问题更清楚 |
| 协议隔离 | TCP 443 和 UDP 443 是独立的传输层，可以共存 |
| 避免冲突 | 不能让两个服务同时占用 UDP 443 |

> **核心原则：** 不动现有 3X-UI，因为 Reality 是主力稳定节点。

---

## 推荐架构

```
DMIT VPS (你的 VPS IP)
├── 3X-UI / Xray Reality
│   └── TCP 443  ← 主力稳定节点
│
└── Hysteria 2 (官方 systemd 服务)
    └── UDP 443  ← 高速备用节点

trafficStats API: 127.0.0.1:9999 (仅本地访问)
```

**支持的客户端：**

| 客户端 | 平台 | 推荐度 |
|--------|------|--------|
| sing-box | 全平台 CLI | ⭐⭐⭐⭐⭐ 推荐 |
| Hiddify / Hiddify Next | iOS / Android / 桌面 | ⭐⭐⭐⭐⭐ |
| v2rayN | Windows | ⭐⭐⭐⭐ |
| Shadowrocket | iOS | ⭐⭐⭐⭐ |
| Mihomo / Clash Meta | 全平台 | ⭐⭐⭐⭐ |

---

## 快速开始

### 前提条件

1. 一台 VPS（已安装 3X-UI / Xray Reality，占用 TCP 443）
2. 一个域名，DNS A 记录指向 VPS IP
3. **Cloudflare 必须设置为 DNS only（灰色云），不能开橙云代理**

### 部署步骤

```bash
# 1. 克隆仓库
git clone https://github.com/conanxin/dmit-hysteria2-proxy.git
cd dmit-hysteria2-proxy

# 2. 设置你的域名（必须修改为你自己的域名）
export HY2_DOMAIN=hy2.example.com

# 3. 可选：自定义密码（不设置则自动随机生成）
export HY2_AUTH_PASSWORD=你的强密码
export HY2_OBFS_PASSWORD=你的混淆密码

# 4. 执行部署（需要 root 权限）
sudo -E ./scripts/install-hysteria2-server.sh
```

> ⚠️ **注意：** `HY2_DOMAIN` 必须换成你自己的域名，且 DNS A 记录已指向 VPS IP。

### 部署后

部署完成后，真实客户端信息保存在 VPS 本地：

```bash
sudo cat /root/hysteria2-client-info.txt
```

这个文件包含：
- `hysteria2://` 分享链接（导入客户端最方便）
- 官方客户端 YAML 配置
- sing-box outbound JSON
- Mihomo proxy YAML

---

## DNS 设置

### Cloudflare 设置

| 类型 | 名称 | 值 | 代理状态 |
|------|------|-----|----------|
| A | hy2 | 你的 VPS IPv4 | **DNS only（灰色云）** |

> ⚠️ **重要：** 不要开启 Cloudflare 橙云代理！
> Hysteria 2 走 UDP/QUIC 协议，不能通过普通 Cloudflare CDN 代理。
> 开启橙云会导致连接失败。

### 其他 DNS 服务商

如果使用其他 DNS 服务商（如 Route53、Namecheap 等），只需确保：
- A 记录指向 VPS IP
- 没有开启任何 HTTP/HTTPS 代理或 CDN

---

## 部署后如何导入客户端

### 方法一：分享链接（最方便）

1. SSH 到 VPS：`sudo cat /root/hysteria2-client-info.txt`
2. 复制 `hysteria2://` 开头的整行
3. 在客户端中选择「从剪贴板导入」

### 方法二：手动配置

如果分享链接无法自动导入，可以参考 [docs/CLIENT_IMPORT_CHECKLIST.md](./docs/CLIENT_IMPORT_CHECKLIST.md) 中的手动配置说明。

---

## Windows / v2rayN

### 导入步骤

1. 打开 v2rayN
2. 顶部菜单：**服务器** → **从剪贴板导入**
3. 粘贴从 VPS 复制的 `hysteria2://` 链接
4. 节点自动出现在服务器列表中，名称为 `DMIT-HY2`
5. 选中该节点，按 Enter 激活
6. 右键系统托盘图标 → **系统代理** → **设置系统代理**

### 推荐设置

| 设置项 | 推荐值 |
|--------|--------|
| 核心类型 | sing-box（性能更好） |
| 系统代理 | 自动配置 |
| 路由模式 | 绕过大陆 / Whitelist |

### 测试

浏览器访问 `https://ip.sb`，应显示你的 VPS IP。

---

## iPhone / Hiddify

### 导入步骤

1. 打开 Hiddify
2. 点击 **+** 按钮（手机版右下角，桌面版左上角）
3. 选择 **从剪贴板导入**
4. 粘贴 `hysteria2://` 链接
5. 节点出现为 **DMIT-HY2**

### 推荐设置

| 设置项 | 推荐值 | 说明 |
|--------|--------|------|
| 节点 | DMIT-HY2 | 选择刚导入的节点 |
| 模式 | VPN | 全局代理模式 |
| WARP | 关闭 | 避免冲突 |
| 地区 | 中国 (cn) | 路由优化 |
| 拦截广告 | 先关闭 | 排除问题后再开 |
| 绕过局域网 | 开启 | 不影响内网访问 |
| 解析目的地 | 先关闭 | 排除问题后再开 |
| IPv6 路由 | 先禁用 | 如果 VPS 有 IPv6 可以后续开启 |

### 测试

打开 Safari 访问 `https://ip.sb`，应显示 VPS IP（IPv4 或 IPv6）。

---

## Shadowrocket

### 导入步骤

1. 打开 Shadowrocket
2. 点击右上角 **+**
3. 点击 **Type** → 滚动到底部 → 选择 **Hysteria2**
4. 点击顶部 **URL**，粘贴 `hysteria2://` 链接
5. 或者手动填写以下字段：

| 字段 | 填写内容 |
|------|----------|
| Type | Hysteria2 |
| Address | 你的域名（如 hy2.example.com） |
| Port | 443 |
| Auth | Password |
| Password | （从 client-info.txt 获取） |
| Obfuscation | salamander |
| Obfuscation Password | （从 client-info.txt 获取） |
| Allow Insecure | ON（仅使用自签证书时需要） |
| SNI | 你的域名 |

### 测试

打开浏览器访问 `https://ip.sb`，确认显示的 IP 是你的 VPS。

---

## 本地代理端口

使用官方 Hysteria 2 客户端启动时，本地会开放以下代理端口：

```
SOCKS5: 127.0.0.1:7898
HTTP:    127.0.0.1:7899
```

### 快速测试

```bash
curl -x socks5h://127.0.0.1:7898 https://ip.sb
```

返回 VPS 的 IPv4 或 IPv6 都说明代理可用。

---

## 手机 Hiddify 推荐设置

| 设置 | 推荐 |
|------|------|
| 节点 | DMIT-HY2 |
| 模式 | VPN |
| WARP | 关闭 |
| 地区 | 中国 cn |
| 拦截广告 | 先关闭 |
| 绕过局域网 | 开启 |
| 解析目的地 | 先关闭 |
| IPv6 路由 | 先禁用 |

---

## 多设备使用

### 可以共用一个账号吗？

可以，但不推荐长期使用同一个 `hysteria2://` 链接在多台设备上。

### 推荐做法

为每台设备创建独立账号，方便：
- 分别统计流量
- 单独撤销某台设备的访问权限
- 某台设备凭证泄露时影响范围更小

**建议账号命名：**
- `conan-main`（主力电脑）
- `conan-phone`（手机）
- `conan-ipad`（iPad）
- `conan-hermes`（其他设备）

### 如何添加新用户

SSH 到 VPS，编辑服务端配置：

```bash
nano /etc/hysteria/config.yaml
```

在 `auth.userpass:` 下新增一行：

```yaml
auth:
  type: userpass
  userpass:
    conan-main: 已有密码
    conan-phone: 新密码123  # 新增这行
```

保存后重启服务：

```bash
systemctl restart hysteria-server
```

> 💡 提示：新密码可以用 `openssl rand -base64 32` 生成。

---

## 安全说明

> ⚠️ **非常重要，请仔细阅读。**

### `hysteria2://` 链接 = 账号密码

分享链接里包含了：
- 服务器地址
- 用户名和密码
- obfs 混淆密码

**任何人拿到这个链接都可以使用你的代理节点。**

### 安全守则

| ✅ 可以做 | ❌ 不要做 |
|----------|----------|
| 保存在 VPS `/root/hysteria2-client-info.txt` | 提交到 GitHub |
| 保存在本机私有文件 | 发到公开群 / 社交媒体 |
| 通过端到端加密方式发送 | 截图公开二维码 |
| 定期更换密码 | 把链接写在代码注释里 |

### 仓库安全

本仓库的 `.gitignore` 已屏蔽以下敏感文件：

```
.env
*.secret
*.key
*.pem
*.crt
client-info.txt
share-link.txt
actual-config.yaml
reports/*_PRIVATE*.md
```

提交前仍建议检查：

```bash
git grep -n "hysteria2://.*@" || true
git grep -n "obfs-password=.*[A-Za-z0-9]" || true
```

---

## 日常维护

### 查看服务状态

```bash
systemctl status hysteria-server --no-pager
```

### 查看日志

```bash
# 最近日志
journalctl -u hysteria-server -e --no-pager

# 实时日志（Ctrl+C 退出）
journalctl -u hysteria-server -f
```

### 端口监听检查

```bash
# UDP 443 (Hysteria 2)
ss -ulnp | grep ':443'

# TCP 443 (Reality)
ss -tlnp | grep ':443'

# trafficStats API
ss -tlnp | grep ':9999'
```

### 查看客户端信息

```bash
sudo cat /root/hysteria2-client-info.txt
```

### 健康检查

```bash
./scripts/healthcheck.sh
```

### 重启服务

```bash
systemctl restart hysteria-server
```

---

## 升级 Hysteria 2

```bash
# 使用官方脚本升级
bash <(curl -fsSL https://get.hy2.sh/)

# 重启服务
systemctl restart hysteria-server

# 确认状态
systemctl status hysteria-server --no-pager
```

升级会保留 `/etc/hysteria/config.yaml`，不会丢失配置。

---

## 证书续期

如果使用 Let's Encrypt 或 acme.sh，证书会自动续期。续期后需要重启 Hysteria 2 以加载新证书：

```bash
systemctl restart hysteria-server
```

建议在 acme.sh 的续期后钩子（post-hook）中自动执行重启。

---

## 卸载 Hysteria 2

```bash
sudo ./scripts/uninstall-hysteria2-server.sh
```

这会移除：
- Hysteria 2 二进制文件
- `/etc/hysteria/` 配置目录
- `hysteria-server.service` systemd 单元
- `/root/hysteria2-client-info.txt`

**不会触碰：**
- 3X-UI / Xray Reality
- nginx
- 任何 TCP 端口规则

---

## 常见问题

### 客户端连接超时（timeout）

**检查清单：**

- [ ] UDP 443 是否被防火墙阻挡（VPS 或客户端网络）
- [ ] 域名是否解析到 VPS IP（`dig +short 你的域名`）
- [ ] Cloudflare 是否设置为 DNS only（灰色云）
- [ ] obfs 密码是否和服务端一致
- [ ] `hysteria-server.service` 是否 active

```bash
# 在 VPS 上检查
systemctl status hysteria-server --no-pager
ss -ulnp | grep ':443'
```

### 认证失败（auth failed）

检查用户名和密码是否正确：

```bash
# 在 VPS 上重新查看凭证
sudo cat /root/hysteria2-client-info.txt
```

确认客户端使用的是 `userpass` 认证方式，且用户名:密码格式正确。

### iPhone 显示已连接但网站打不开

**排查步骤：**

1. 确认 Hiddify 中选中的是 `DMIT-HY2` 节点
2. 确认 WARP 已关闭（避免冲突）
3. 路由设置是否过于复杂 → 先改用简单路由测试
4. 尝试关闭 IPv6 路由

### v2rayN 里有些网站走代理，有些不走

这是正常的路由分流行为：

- `proxy` = 走代理
- `direct` = 直连

Hysteria 2 是**出口线路**，哪些网站走代理、哪些直连，由 v2rayN 的路由规则决定，不是 Hysteria 2 服务端控制的。

### Hysteria 2 速度慢

**可能原因：**

1. 带宽限制设置过低 → 编辑 `/etc/hysteria/config.yaml` 调整 `bandwidth`
2. VPS 网络拥堵 → 对比 Reality 节点的速度
3. 客户端网络条件差 → 尝试切换网络

```bash
# 修改带宽限制（需要重启服务）
nano /etc/hysteria/config.yaml
# 修改 bandwidth.up 和 bandwidth.down 的值
systemctl restart hysteria-server
```

---

## 项目文件结构

```
dmit-hysteria2-proxy/
├── README.md               # 英文说明
├── README.zh-CN.md        # 中文说明（本文件）
├── LICENSE                 # MIT 开源协议
├── .gitignore              # 屏蔽敏感文件
├── .env.example            # 环境变量模板
│
├── scripts/                # 部署和维护脚本
│   ├── preflight.sh                  # 部署前环境检查
│   ├── install-hysteria2-server.sh   # 主部署脚本
│   ├── render-server-config.sh       # 服务端配置渲染
│   ├── render-client-info.sh         # 客户端信息生成
│   ├── healthcheck.sh                # 服务健康检查
│   └── uninstall-hysteria2-server.sh # 卸载脚本
│
├── templates/              # 配置模板
│   ├── server.tls.yaml.tpl           # 真实证书的服务端配置模板
│   ├── server.selfsigned.yaml.tpl    # 自签证书的服务端配置模板
│   ├── client.official.yaml.tpl      # 官方客户端配置模板
│   ├── client.sing-box-outbound.json.tpl
│   └── client.mihomo.yaml.tpl
│
├── docs/                  # 详细文档
│   ├── DMIT_3XUI_COEXISTENCE.md
│   ├── CLIENT_USAGE.md
│   ├── CLIENT_IMPORT_CHECKLIST.md
│   ├── OPERATIONS.md
│   ├── TROUBLESHOOTING.md
│   └── DESIGN_NOTES.md
│
└── reports/              # 部署验收报告（脱敏）
    └── .gitkeep
```

---

## 后续开发路线

- [ ] 多设备账号管理脚本
- [ ] 本地二维码分享页面
- [ ] Windows 桌面快捷方式
- [ ] 7 天稳定性观察脚本
- [ ] 接入 Conan VPS Control Tower 只读监控
- [ ] Reality 与 Hysteria 2 速度对比报告

---

## License

MIT — 详见 [LICENSE](./LICENSE)。

---

## 相关链接

- [Hysteria 2 官方文档](https://hysteria.io/docs/)
- [Hysteria 2 GitHub](https://github.com/apernet/hysteria)
- [3X-UI 项目](https://github.com/MHSanaei/3x-ui)
- [sing-box 文档](https://sing-box.sagernet.org/)
- [Hiddify 项目](https://github.com/hiddify/hiddify-next)
