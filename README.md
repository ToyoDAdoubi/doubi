# 一个逗比写的逗比脚本

![GitHub](https://img.shields.io/github/license/mashape/apistatus.svg)
[![GitHub stars](https://img.shields.io/github/stars/ToyoDAdoubi/doubi.svg?style=popout&label=Stars)](https://github.com/ToyoDAdoubi/doubi/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/ToyoDAdoubi/doubi.svg?style=popout&label=Fork)](https://github.com/ToyoDAdoubi/doubi/fork)
## 脚本索引

* [***代理相关***](#代理相关)
  * [ss-go.sh](#ss_gosh)
  * [ssr.sh](#ssrsh)
  * [ssrmu.sh](#ssrmush)
  * [brook.sh](#brooksh)
  * [goflyway.sh](#goflywaysh)
  * [daze.sh](#dazesh)
  * [lightsocks.sh](#lightsockssh)
  * [mtproxy.sh](#mtproxysh)
  * [mtproxy_go.sh](#mtproxy_gosh)
* [***中转相关***](#中转相关)
  * [iptables-pf.sh](#iptables-pfsh)
  * [brook-pf.sh](#brook-pfsh)
  * [haproxy.sh](#haproxysh)
  * [socat.sh](#socatsh)
  * [tinymapper.sh](#tinymappersh)
* [***BT下载相关***](#bt下载相关)
  * [aria2.sh](#aria2sh)
  * [cloudt.sh](#cloudtsh)
  * [pserver.sh](#pserversh)
* [***服务器相关***](#服务器相关)
  * [bbr.sh](#bbrsh)
  * [status.sh](#statussh)
  * [ban_iptables.sh](#ban_iptablessh)
  * [ssh_port.sh](#ssh_portsh)
* [***VPN 相关***](#vpn相关)
  * [ocserv.sh](#ocservsh)
* [***DNS 相关***](#dns相关)
  * [dowsdns.sh](#dowsdnssh)
* [***HTTP 相关***](#http相关)
  * [caddy_install.sh](#caddy_installsh)
  * [pythonhttp.sh](#pythonhttpsh)
* [***其他***](#其他)
  * [adbyby.sh](#adbybysh)
  * [gfw_push.sh](#gfw_pushsh)
  * [libsodium.sh](#libsodiumsh)
  * [ssrstatus.sh](#ssrstatussh)
  * [ssr_check.sh](#ssr_checksh)
  * [ssr_ip_check.sh](#ssr_ip_checksh)

---

## 代理相关

## ss_go.sh

- 脚本说明: Shadowsocks 一键安装管理脚本
- 系统支持: CentOS6+ / Debian6+ / Ubuntu14+
- 使用方法: https://doub.io/ss-jc67/
- 项目地址: https://github.com/shadowsocks/go-shadowsocks2

#### 脚本特点:
目前网上的各个Shadowsocks脚本基本都是只有 安装/启动/重启 等基础功能，对于小白来说还是不够简单方便。既然是一键脚本，那么就要尽可能地简单，小白更容易接受使用！

#### 下载安装:
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/ss-go.sh && chmod +x ss-go.sh && bash ss-go.sh
```

---
## ssr.sh

- 脚本说明: ShadowsocksR 一键安装管理脚本，支持单端口/多端口切换和管理
- 系统支持: CentOS6+ / Debian6+ / Ubuntu14+
- 使用方法: https://doub.io/ss-jc42/
- 项目地址: https://github.com/ToyoDAdoubiBackup/shadowsocksr

#### 脚本特点:
目前网上的各个ShadowsocksR脚本基本都是只有 安装/启动/重启 等基础功能，对于小白来说还是不够简单方便。既然是一键脚本，那么就要尽可能地简单，小白更容易接受使用！

- 支持 限制 用户速度
- 支持 限制 端口设备数
- 支持 显示 当前连接IP
- 支持 显示 SS/SSR连接+二维码
- 支持 切换管理 单/多端口
- 支持 一键安装 锐速
- 支持 一键安装 BBR
- 支持 一键封禁 垃圾邮件(SMAP)/BT/PT

#### 下载安装:
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/ssr.sh && chmod +x ssr.sh && bash ssr.sh
```

---
## ssrmu.sh

- 脚本说明: ShadowsocksR 一键安装管理脚本，支持流量控制
- 系统支持: CentOS6+ / Debian6+ / Ubuntu14+
- 使用方法: https://doub.io/ss-jc60/
- 项目地址: https://github.com/ToyoDAdoubiBackup/shadowsocksr

#### 脚本特点:
目前网上的各个ShadowsocksR脚本基本都是只有 安装/启动/重启 等基础功能，对于小白来说还是不够简单方便。既然是一键脚本，那么就要尽可能地简单，小白更容易接受使用！

- 支持 限制 用户速度
- 支持 限制 用户设备数
- 支持 限制 用户总流量
- 支持 定时 流量清零
- 支持 显示 当前连接IP
- 支持 显示 SS/SSR连接+二维码
- 支持 一键安装 锐速
- 支持 一键安装 BBR
- 支持 一键封禁 垃圾邮件(SMAP)/BT/PT

#### 下载安装:
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/ssrmu.sh && chmod +x ssrmu.sh && bash ssrmu.sh
```

---
## brook.sh

- 脚本说明: Brook 一键安装管理脚本
- 系统支持: CentOS6+ / Debian7+ / Ubuntu14+
- 使用方法: https://doub.io/brook-jc3/

#### 下载安装:
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/brook.sh && chmod +x brook.sh && bash brook.sh
```

---
## goflyway.sh

- 脚本说明: GoFlyway 一键安装管理脚本
- 系统支持: CentOS6+ / Debian7+ / Ubuntu14+
- 使用方法: https://doub.io/goflyway-jc2/

#### 下载安装:
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/goflyway.sh && chmod +x goflyway.sh && bash goflyway.sh
```

---
## lightsocks.sh

- 脚本说明: LightSocks 一键安装管理脚本
- 系统支持: CentOS6+ / Debian7+ / Ubuntu14+
- 使用方法: https://doub.io/lightsocks-jc1/

#### 下载安装:
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/lightsocks.sh && chmod +x lightsocks.sh && bash lightsocks.sh
```

---
## daze.sh

- 脚本说明: DAZE 一键安装管理脚本
- 系统支持: CentOS6+ / Debian7+ / Ubuntu14+
- 使用方法: https://doub.io/daze-jc3/

#### 下载安装:
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/daze.sh && chmod +x daze.sh && bash daze.sh
```

---
## mtproxy.sh

- 脚本说明: Mtproto Proxy 一键安装管理脚本
- 系统支持: CentOS7 / Debian7+ / Ubuntu14+
- 使用方法: https://doub.io/shell-jc7/

#### 下载安装:
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/mtproxy.sh && chmod +x mtproxy.sh && bash mtproxy.sh
```

---
## mtproxy_go.sh

- 脚本说明: Mtproto Proxy Go版 一键安装管理脚本
- 系统支持: CentOS6+ / Debian7+ / Ubuntu14+
- 使用方法: https://doub.io/shell-jc9/

#### 下载安装:
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/mtproxy_go.sh && chmod +x mtproxy_go.sh && bash mtproxy_go.sh
```

---

## 中转相关

## iptables-pf.sh

- 脚本说明: iptables 端口转发 一键安装管理脚本
- 系统支持: CentOS6+ / Debian6+ / Ubuntu14+
- 使用方法: https://doub.io/wlzy-20/

#### 下载安装:
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/iptables-pf.sh && chmod +x iptables-pf.sh && bash iptables-pf.sh
```

---
## brook-pf.sh

- 脚本说明: Brook 端口转发 一键安装管理脚本
- 系统支持: CentOS6+ / Debian6+ / Ubuntu14+
- 使用方法: https://doub.io/wlzy-37/

#### 下载安装:
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/brook-pf.sh && chmod +x brook-pf.sh && bash brook-pf.sh
```

---
## haproxy.sh

- 脚本说明: HaProxy 一键安装管理脚本
- 系统支持: CentOS6+ / Debian6+ / Ubuntu14+
- 使用方法: https://doub.io/wlzy-19/

#### 下载安装:
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/haproxy.sh && chmod +x haproxy.sh && bash haproxy.sh
```

---
## socat.sh

- 脚本说明: Socat 一键安装管理脚本
- 系统支持: CentOS6+ / Debian6+ / Ubuntu14+
- 使用方法: https://doub.io/wlzy-18/

#### 下载安装:
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/socat.sh && chmod +x socat.sh && bash socat.sh
```

---
## tinymapper.sh

- 脚本说明: tinyPortMapper 一键安装管理脚本
- 系统支持: CentOS6+ / Debian6+ / Ubuntu14+
- 使用方法: https://doub.io/wlzy-36/

#### 下载安装:
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/tinymapper.sh && chmod +x tinymapper.sh && bash tinymapper.sh
```

---

## BT下载相关

## aria2.sh

- 脚本说明: Aria2 一键安装管理脚本
- 系统支持: CentOS6+ / Debian6+ / Ubuntu14+
- 使用方法: https://doub.io/shell-jc4/

#### 下载安装:
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/aria2.sh && chmod +x aria2.sh && bash aria2.sh
```

---
## cloudt.sh

- 脚本说明: Cloud Torrent 一键安装管理脚本
- 系统支持: CentOS6+ / Debian6+ / Ubuntu14+
- 使用方法: https://doub.io/wlzy-12/
- 项目地址: https://github.com/jpillora/cloud-torrent

#### 下载安装:
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/cloudt.sh && chmod +x cloudt.sh && bash cloudt.sh
```

---
## pserver.sh

- 脚本说明: Peerflix Server 一键安装管理脚本
- 系统支持: CentOS6+ / Debian6+ / Ubuntu14+
- 使用方法: https://doub.io/wlzy-13/
- 项目地址: https://github.com/asapach/peerflix-server

#### 下载安装:
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/pserver.sh && chmod +x pserver.sh && bash pserver.sh
```

---

## 服务器相关

## bbr.sh

- 脚本说明: BBR 一键安装管理脚本
- 系统支持: Debian6+ / Ubuntu14+
- 使用方法: https://doub.io/wlzy-16/

#### 下载安装:
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/bbr.sh && chmod +x bbr.sh && bash bbr.sh
```

---
## status.sh

- 脚本说明: ServerStatus 一键安装管理脚本
- 系统支持: CentOS6+ / Debian6+ / Ubuntu14+
- 使用方法: https://doub.io/shell-jc3/

#### 下载安装:
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/status.sh && chmod +x status.sh && bash status.sh
```

---
## ban_iptables.sh

- 脚本说明: iptables 垃圾邮件(SPAM)/BT/PT 一键封禁脚本
- 系统支持: CentOS6+ / Debian6+ / Ubuntu14+
- 使用方法: https://doub.io/shell-jc2/

#### 下载安装:
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/ban_iptables.sh && chmod +x ban_iptables.sh && bash ban_iptables.sh
```

---
## ssh_port.sh

- 脚本说明: SSH 一键修改端口脚本
- 系统支持: Debian6+ / Ubuntu14+
- 使用方法: https://doub.io/linux-jc11/

#### 下载安装:
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/ssh_port.sh && chmod +x ssh_port.sh && bash ssh_port.sh
```

---

## VPN相关

## ocserv.sh

- 脚本说明: Ocserv AnyConnect 一键安装管理脚本
- 系统支持: Debian7+ / Ubuntu14+
- 使用方法: https://doub.io/vpnzy-7/

#### 下载安装:
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/ocserv.sh && chmod +x ocserv.sh && bash ocserv.sh
```

---

## DNS相关

## dowsdns.sh

- 脚本说明: DowsDNS 一键安装管理脚本
- 系统支持: CentOS7 / Debian7+ / Ubuntu14+
- 使用方法: https://doub.io/dowsdns-jc3/

#### 下载安装:
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/dowsdns.sh && chmod +x dowsdns.sh && bash dowsdns.sh
```

---

## HTTP相关

## caddy_install.sh

- 脚本说明: Caddy 一键安装脚本
- 系统支持: CentOS6+ / Debian7+ / Ubuntu14+
- 使用方法: https://doub.io/shell-jc1

#### 下载安装:
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/caddy_install.sh && chmod +x caddy_install.sh && bash caddy_install.sh
 # 安装插件：
 bash caddy_install.sh xxx,xxx
  # 例如同时安装 http.filemanager 和 http.webdav插件：
  bash caddy_install.sh http.filemanager,http.webdav
  # 插件和Caddy是集成在一起的(单个二进制文件)，多个插件必须同时安装。
# 卸载命令：
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/caddy_install.sh && chmod +x caddy_install.sh && caddy_install.sh uninstall
```

---
## pythonhttp.sh

- 脚本说明: SimpleHTTPServer 一键安装管理脚本
- 系统支持: CentOS6+ / Debian6+ / Ubuntu14+
- 使用方法: https://doub.io/wlzy-8/

#### 下载安装:
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/pythonhttp.sh && chmod +x pythonhttp.sh && bash pythonhttp.sh
```

---

## 其他

## adbyby.sh

- 脚本说明: ADbyby 一键安装管理脚本
- 系统支持: CentOS6+ / Debian6+ / Ubuntu14+
- 使用方法: https://doub.io/adbyby-jc2/

#### 下载安装:
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/adbyby.sh && chmod +x adbyby.sh && bash adbyby.sh
```

## gfw_push.sh

- 脚本说明: 监测服务器IP是否被墙并推送至 Telegram 一键脚本
- 系统支持: CentOS6+ / Debian6+ / Ubuntu14+
- 使用方法: https://doub.io/shell-jc8/

#### 下载安装:
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/gfw_push.sh && chmod +x gfw_push.sh && bash gfw_push.sh
```

---
## libsodium.sh

- 脚本说明: libsodium 一键安装管理脚本
- 系统支持: CentOS6+ / Debian6+ / Ubuntu14+
- 使用方法: https://doub.io/shell-jc6/

#### 下载安装:
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/libsodium.sh && chmod +x libsodium.sh && bash libsodium.sh
```

---
## ssr_check.sh

- 脚本说明: ShadowsocksR 批量快速验证账号可用性
- 系统支持: CentOS6+ / Debian6+ / Ubuntu14+
- 使用方法: https://doub.io/ss-jc56/

#### 下载安装:
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/ssr_check.sh && chmod +x ssr_check.sh
```

---
## ssrstatus.sh

- 脚本说明: ShadowsocksR 账号在线监控网站
- 系统支持: CentOS6+ / Debian6+ / Ubuntu14+
- 使用方法: https://doub.io/shell-jc5/

#### 下载安装:
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/ssrstatus.sh && chmod +x ssrstatus.sh && bash ssrstatus
```

---
## ssr_ip_check.sh

- 脚本说明: ShadowsocksR 检测每个端口链接IP数
- 系统支持: CentOS6+ / Debian6+ / Ubuntu14+
- 使用方法: https://doub.io/ss-jc50/

#### 下载安装:
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/ssr_ip_check.sh && chmod +x ssr_ip_check.sh
```

---
## ~~pipes.sh~~

- 脚本说明: PipeSocks 一键安装管理脚本（该软件已停更）
- 系统支持: CentOS7 / Debian7+ / Ubuntu14+
- 使用方法: https://doub.io/pipesocks-jc2/

#### 下载安装:
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/pipesocks/install/master/install.sh && mv install.sh pipes.sh && chmod +x pipes.sh && bash pipes.sh
```

---
## ~~gogo.sh~~

- 脚本说明: GoGo Tunnel 一键安装管理脚本（该软件已停更）
- 系统支持: CentOS6+ / Debian6+ / Ubuntu14+
- 使用方法: https://doub.io/wlzy-24/

#### 下载安装:
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/gogo.sh && chmod +x gogo.sh && bash gogo.sh
```

---
Copyright (C) 2016-2018 Toyo <https://doub.io>
