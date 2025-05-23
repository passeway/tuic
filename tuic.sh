#!/bin/bash

set -e

# 必须使用 root 权限执行
if [ "$(id -u)" -ne 0 ]; then
  echo "请以 root 权限运行此脚本！"
  exit 1
fi

# 获取系统架构
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
  ARCH_NAME="x86_64"
elif [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
  ARCH_NAME="aarch64"
else
  echo "不支持的架构: $ARCH"
  exit 1
fi

# 获取 TUIC 最新版本号
LATEST_VER=$(curl -s https://api.github.com/repos/Itsusinn/tuic/releases/latest | grep tag_name | cut -d '"' -f4)

if [ -z "$LATEST_VER" ]; then
  echo "无法获取 TUIC 最新版本"
  exit 1
fi

# 创建安装目录
mkdir -p /opt/tuic

# 下载 tuic-server
wget -q --show-progress -O /opt/tuic/tuic-server "https://github.com/Itsusinn/tuic/releases/download/${LATEST_VER}/tuic-server-${ARCH_NAME}-linux" || { echo "下载失败！"; exit 1; }
chmod +x /opt/tuic/tuic-server


# 生成随机端口号并检查是否被占用
while true; do
    RANDOM_PORT=$(shuf -i 50000-55000 -n 1)
    if ! ss -tuln | grep -q ":$RANDOM_PORT "; then
        echo "Selected port: $RANDOM_PORT"
        break
    else
        echo "Port $RANDOM_PORT is in use, selecting a new one."
    fi
done

# 生成 UUID 和随机密码
UUID=$(cat /proc/sys/kernel/random/uuid)
RANDOM_PSK=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 12)

# 生成自签证书
openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) \
  -keyout /opt/tuic/server.key \
  -out /opt/tuic/server.crt \
  -subj "/CN=bing.com" \
  -days 36500

# 创建配置文件
cat > /opt/tuic/config.json <<EOF
{
    "server": "[::]:$RANDOM_PORT",
    "users": {
        "$UUID": "$RANDOM_PSK"
    },
    "certificate": "/opt/tuic/server.crt",
    "private_key": "/opt/tuic/server.key",
    "congestion_control": "bbr",
    "alpn": ["h3", "spdy/3.1"],
    "udp_relay_ipv6": true,
    "zero_rtt_handshake": false,
    "auth_timeout": "3s",
    "max_idle_time": "10s",
    "max_external_packet_size": 1500,
    "gc_interval": "3s",
    "gc_lifetime": "15s",
    "log_level": "warn"
}
EOF

# 写入 systemd 服务
cat > /etc/systemd/system/tuic.service <<EOF
[Unit]
Description=Delicately-TUICed high-performance proxy built on top of the QUIC protocol
Documentation=https://github.com/EAimTY/tuic
After=network.target

[Service]
User=root
WorkingDirectory=/opt/tuic
ExecStart=/opt/tuic/tuic-server -c config.json
Restart=on-failure
RestartPreventExitStatus=1
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 启用并启动服务
systemctl daemon-reload
systemctl enable --now tuic.service


# 获取本机 IP 和国家
HOST_IP=$(curl -s https://checkip.amazonaws.com || curl -s https://icanhazip.com)
IP_COUNTRY=$(curl -s http://ipinfo.io/${HOST_IP}/country)

# 生成客户端配置文本
cat > /opt/tuic/config.txt <<EOF

tuic://$UUID:$RANDOM_PSK@$HOST_IP:$RANDOM_PORT?sni=www.bing.com&congestion_control=bbr&udp_relay_mode=quic&alpn=h3&allow_insecure=1#$IP_COUNTRY

$IP_COUNTRY = tuic, $HOST_IP, $RANDOM_PORT, skip-cert-verify=true, sni=www.bing.com, uuid=$UUID, alpn=h3, password=$RANDOM_PSK, version=5
EOF
# 输出客户端配置文本
cat /opt/tuic/config.txt
