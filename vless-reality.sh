#!/bin/bash
# 一键安装 VLESS + Reality 并生成可直接导入 v2rayN 的链接
set -e

# 检查 root
if [ "$(id -u)" -ne 0 ]; then
  echo "请用 root 运行"
  exit 1
fi

echo "更新系统并安装依赖..."
apt update -y && apt install -y curl socat

echo "安装 Xray..."
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# 生成 UUID
UUID=$(cat /proc/sys/kernel/random/uuid)

# 生成 Reality 密钥对
KEYPAIR=$(xray x25519)
PRIVATE_KEY=$(echo "$KEYPAIR" | grep Private | awk '{print $3}')
PUBLIC_KEY=$(echo "$KEYPAIR" | grep Public | awk '{print $3}')

# 设置端口和伪装网站
PORT=443
DEST="www.cloudflare.com"

# 写入 config.json
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
          "serverNames": ["$DEST"],
          "privateKey": "$PRIVATE_KEY",
          "shortIds": [""]
        }
      }
    }
  ],
  "outbounds": [{"protocol": "freedom"}]
}
EOF

# 启动并自启 Xray
systemctl enable xray
systemctl restart xray

# 输出可直接导入 v2rayN 的 vless:// 链接
IP=$(curl -s ipv4.icanhazip.com)
VLESS_LINK="vless://$UUID@$IP:$PORT?encryption=none&security=reality&sni=$DEST&fp=chrome&pbk=$PUBLIC_KEY&type=tcp&flow=xtls-rprx-vision#VLESS-Reality"

echo -e "\n✅ 安装完成！直接复制下面链接到 v2rayN / Clash 即可使用：\n"
echo "$VLESS_LINK"
