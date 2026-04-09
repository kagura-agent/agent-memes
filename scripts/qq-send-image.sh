#!/bin/bash
# Usage: qq-send-image.sh <channel_id> <image_path> [caption]
# QQ Bot API image send via curl.
#
# Env vars (all optional):
#   QQ_BOT_TOKEN  - bot token (preferred, avoids reading openclaw.json)
#   QQ_BOT_APPID  - bot app ID (preferred)
#   QQ_PROXY      - proxy URL for curl (default: none)

set -euo pipefail

CHANNEL_ID="${1:?Usage: qq-send-image.sh <channel_id> <image_path> [caption]}"
IMAGE_PATH="${2:?Missing image path}"
CAPTION="${3:-}"

if [ -n "${QQ_BOT_TOKEN:-}" ]; then
  TOKEN="$QQ_BOT_TOKEN"
  APPID="${QQ_BOT_APPID:?QQ_BOT_APPID is required when using QQ_BOT_TOKEN}"
else
  read -r TOKEN APPID < <(node -e "
const c=JSON.parse(require('fs').readFileSync(require('os').homedir()+'/.openclaw/openclaw.json','utf8'));
const q=c.channels?.qqbot||c.channels?.qq||{};
const t=q.token||'';const a=q.appId||q.app_id||'';
if(!t||!a){console.error('Set QQ_BOT_TOKEN+QQ_BOT_APPID or configure openclaw.json channels.qqbot');process.exit(1)}
console.log(t+' '+a);
")
fi

PROXY="${QQ_PROXY:-${https_proxy:-${HTTPS_PROXY:-}}}"
PROXY_ARGS=()
if [ -n "$PROXY" ]; then
  PROXY_ARGS=(-x "$PROXY")
fi

CURL_ARGS=(
  -s
  --max-time 30
  -H "Authorization: Bot ${APPID}.${TOKEN}"
  -F "msg_id=0"
  -F "file_image=@${IMAGE_PATH}"
)

if [ -n "$CAPTION" ]; then
  CURL_ARGS+=(-F "content=${CAPTION}")
fi

RESULT=$(curl "${CURL_ARGS[@]}" "${PROXY_ARGS[@]}" \
  "https://api.sgroup.qq.com/channels/${CHANNEL_ID}/messages")

echo "$RESULT" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{const r=JSON.parse(d);if(r.id)console.log('Sent! Message ID: '+r.id);else{console.error(r.message||JSON.stringify(r));process.exit(1)}}catch{console.error(d);process.exit(1)}})"
