#!/bin/bash
# VLESS + Reality 一键安装脚本 (Debian/Ubuntu)

set -e

# 检查 root
if [ "$(id -u)" -ne 0 ]; then
  echo "请使用 root 运行此脚本"
  exit 1
fi

# 更新系统
apt update -y && apt upgrade -y

# 安装依赖
apt install -y curl jq socat

# 下载并安装 Xray
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# 生成 UUID
UUID=$(cat /proc/sys/kernel/random/uuid)

# 生成 Reality 密钥对
KEYPAIR=$(xray x25519)
PRIVATE_KEY=$(echo "$KEYPAIR" | grep Private | awk '{print $3}')
PUBLIC_KEY=$(echo "$KEYPAIR" | grep Public | awk '{print $3}')

# 指定端口
PORT=443

# 目标网站 (用于伪装)
DEST="www.cloudflare.com"

# 生成配置文件
cat > /usr/local/etc/xray/config.json <<EOF
{
  "inbounds": [
    {
      "port": $PORT,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "$DEST:443",
          "xver": 0,
          "serverNames": [
            "$DEST"
          ],
          "privateKey": "$PRIVATE_KEY",
          "shortIds": [
            ""
          ]
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
EOF

# 启动并设置自启
systemctl enable xray
systemctl restart xray

echo -e "\n✅ VLESS + Reality 安装完成\n"
echo "-----------------------------"
echo "地址: $(curl -s ipv4.icanhazip.com)"
echo "端口: $PORT"
echo "UUID: $UUID"
echo "PublicKey: $PUBLIC_KEY"
echo "ServerName: $DEST"
echo "ShortId: (留空即可)"
echo "传输: TCP + Reality"
echo "-----------------------------"
