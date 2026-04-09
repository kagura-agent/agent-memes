#!/bin/bash
# Usage: line-send-image.sh <user_or_group_id> <image_url> [caption]
# Send an image via LINE Messaging API (push message).
#
# LINE image messages require publicly accessible URLs (originalContentUrl + previewImageUrl).
# If you have a local file, upload it to a public URL first (e.g. imgur, S3, etc.).
#
# Env vars (all optional):
#   LINE_CHANNEL_ACCESS_TOKEN - channel access token (preferred)
#   LINE_ACCOUNT              - account name in openclaw.json (fallback)
#   LINE_PROXY                - proxy URL for curl (default: none)

set -euo pipefail

TARGET_ID="${1:?Usage: line-send-image.sh <user_or_group_id> <image_url> [caption]}"
IMAGE_URL="${2:?Missing image URL (must be a publicly accessible https URL)}"
CAPTION="${3:-}"

# Validate URL
if [[ ! "$IMAGE_URL" =~ ^https?:// ]]; then
  echo "Error: IMAGE_URL must be a publicly accessible http(s) URL." >&2
  echo "LINE does not support local file paths. Upload the image first." >&2
  exit 1
fi

ACCOUNT="${LINE_ACCOUNT:-}"

# Read token: env var preferred, fallback to openclaw config
if [ -n "${LINE_CHANNEL_ACCESS_TOKEN:-}" ]; then
  TOKEN="$LINE_CHANNEL_ACCESS_TOKEN"
else
  TOKEN=$(node -e "
const c=JSON.parse(require('fs').readFileSync(require('os').homedir()+'/.openclaw/openclaw.json','utf8'));
const accts = c.channels?.line?.accounts || {};
const name = '${ACCOUNT}' || Object.keys(accts)[0] || '';
const token = accts[name]?.channelAccessToken || accts[name]?.token || '';
if (!token) { console.error('No token found. Set LINE_CHANNEL_ACCESS_TOKEN or configure openclaw.json channels.line'); process.exit(1); }
console.log(token);
")
fi

# Build messages array
MESSAGES='[{"type":"image","originalContentUrl":"'"$IMAGE_URL"'","previewImageUrl":"'"$IMAGE_URL"'"}]'
if [ -n "$CAPTION" ]; then
  MESSAGES='[{"type":"text","text":"'"$(echo "$CAPTION" | sed 's/"/\\"/g')"'"},{"type":"image","originalContentUrl":"'"$IMAGE_URL"'","previewImageUrl":"'"$IMAGE_URL"'"}]'
fi

PAYLOAD=$(cat <<EOF
{"to":"${TARGET_ID}","messages":${MESSAGES}}
EOF
)

CURL_ARGS=(
  -s
  --max-time 15
  -H "Content-Type: application/json"
  -H "Authorization: Bearer $TOKEN"
  -d "$PAYLOAD"
)

# Add proxy if configured
PROXY="${LINE_PROXY:-${https_proxy:-${HTTPS_PROXY:-}}}"
if [ -n "$PROXY" ]; then
  CURL_ARGS+=(-x "$PROXY")
fi

RESULT=$(curl "${CURL_ARGS[@]}" "https://api.line.me/v2/bot/message/push")

# LINE returns {} on success, or {"message":"error..."} on failure
if echo "$RESULT" | grep -q '"message"'; then
  echo "Error: $RESULT" >&2
  exit 1
fi

echo "Sent!"
