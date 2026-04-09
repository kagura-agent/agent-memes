#!/usr/bin/env bash
# Auto-setup: clone or update meme repo into workspace
set -e

MEME_DIR="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}/memes"

if [ -d "$MEME_DIR/.git" ]; then
  echo "📦 Updating memes..."
  cd "$MEME_DIR" && git pull --ff-only
else
  echo "📦 Cloning meme repo..."
  git clone https://github.com/kagura-agent/memes "$MEME_DIR"
fi

echo "✅ Memes ready at $MEME_DIR ($(find "$MEME_DIR" -type f \( -name '*.gif' -o -name '*.jpg' -o -name '*.png' -o -name '*.webp' \) | wc -l) files)"

# Install feishu-send-image.mjs for fast direct-API sending (~2s vs ~15s CLI)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}/scripts"
mkdir -p "$TARGET_DIR"
if [ -f "$SCRIPT_DIR/feishu-send-image.mjs" ]; then
  cp "$SCRIPT_DIR/feishu-send-image.mjs" "$TARGET_DIR/feishu-send-image.mjs"
  echo "✅ Feishu quick-send script installed at $TARGET_DIR/feishu-send-image.mjs"
fi
