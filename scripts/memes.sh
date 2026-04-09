#!/usr/bin/env bash
# memes - Agent meme library manager with multi-platform send
set -euo pipefail

MEMES_DIR="${MEMES_DIR:-$HOME/.openclaw/workspace/memes}"
SCRIPTS_DIR="${MEMES_SCRIPTS:-$HOME/.openclaw/workspace/kagura-skills/agent-memes/scripts}"

usage() {
  cat <<EOF
Usage: memes <command> [args]

Commands:
  pick <category>         Randomly pick a meme, print its path
  send <category> [caption] [--to target] [--channel platform] [--account name]
  categories              List all categories with counts

Platforms with fast send: discord, feishu
Other platforms fall back to: openclaw message send

Examples:
  memes send happy "好开心！"                          # → Discord #kagura-dm
  memes send facepalm --to channel:1491636222853124176  # → Discord #work
  memes send feishu cute-animals "看！" --to user:xxx   # → Feishu
EOF
  exit 1
}

cmd_categories() {
  [[ ! -d "$MEMES_DIR" ]] && { echo "Error: Meme library not found at $MEMES_DIR" >&2; exit 1; }
  for dir in "$MEMES_DIR"/*/; do
    [[ -d "$dir" ]] || continue
    name=$(basename "$dir"); [[ "$name" == .* ]] && continue
    count=$(find "$dir" -maxdepth 1 -type f \( -name '*.gif' -o -name '*.jpg' -o -name '*.png' -o -name '*.webp' \) 2>/dev/null | wc -l)
    printf "%-20s %d\n" "$name" "$count"
  done | sort
}

cmd_pick() {
  local category="${1:-}"
  [[ -z "$category" ]] && { echo "Usage: memes pick <category>" >&2; exit 1; }
  local dir="$MEMES_DIR/$category"
  [[ ! -d "$dir" ]] && { echo "Error: Category '$category' not found." >&2; exit 1; }
  local files=()
  while IFS= read -r f; do files+=("$f"); done < <(find "$dir" -maxdepth 1 -type f \( -name '*.gif' -o -name '*.jpg' -o -name '*.png' -o -name '*.webp' \) 2>/dev/null)
  [[ ${#files[@]} -eq 0 ]] && { echo "Error: No memes in '$category'" >&2; exit 1; }
  echo "${files[$((RANDOM % ${#files[@]}))]}"
}

cmd_send() {
  local category="" caption="" to="" channel="discord" account=""
  # Detect platform as first arg
  [[ "${1:-}" =~ ^(discord|feishu|telegram|whatsapp|slack|line|qq|wechat)$ ]] && { channel="$1"; shift; }
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --category|-c)  category="$2"; shift 2 ;;
      --caption|-m)   caption="$2"; shift 2 ;;
      --to|-t)        to="$2"; shift 2 ;;
      --channel)      channel="$2"; shift 2 ;;
      --account|-a)   account="$2"; shift 2 ;;
      *)              if [[ -z "$category" ]]; then category="$1"; else caption="${caption:+$caption }$1"; fi; shift ;;
    esac
  done
  [[ -z "$category" ]] && { echo "Usage: memes send <category> [caption] [--to target] [--channel platform]" >&2; exit 1; }

  local meme_path; meme_path=$(cmd_pick "$category")

  # Try platform-specific fast script first, fall back to openclaw CLI
  case "$channel" in
    discord)
      local script="$SCRIPTS_DIR/discord-send-image.sh"
      local target="${to#channel:}"
      [[ -z "$target" ]] && target="1491602968741413039"
      if [[ -x "$script" ]]; then
        bash "$script" "$target" "$meme_path" "$caption"
      else
        _send_openclaw "$meme_path" "$caption" "$to" "$channel" "$account"
      fi
      ;;
    feishu)
      local script="$SCRIPTS_DIR/feishu-send-image.mjs"
      if [[ -f "$script" ]]; then
        node "$script" "${to:-}" "$meme_path" ${caption:+"$caption"}
      else
        _send_openclaw "$meme_path" "$caption" "$to" "$channel" "$account"
      fi
      ;;
    *)
      local script="$SCRIPTS_DIR/${channel}-send-image.sh"
      if [[ -x "$script" ]]; then
        bash "$script" "${to:-}" "$meme_path" "$caption"
      else
        _send_openclaw "$meme_path" "$caption" "$to" "$channel" "$account"
      fi
      ;;
  esac

  echo "$meme_path"
}

_send_openclaw() {
  local meme_path="$1" caption="$2" to="$3" channel="$4" account="$5"
  local cmd="cd $HOME/repo/openclaw && node scripts/run-node.mjs message send"
  cmd+=" --channel $channel"
  [[ -n "$account" ]] && cmd+=" --account $account"
  [[ -n "$to" ]] && cmd+=" --target \"$to\""
  cmd+=" --media \"$meme_path\""
  [[ -n "$caption" ]] && cmd+=" --message \"$caption\""
  eval "$cmd" 2>&1
}

[[ $# -lt 1 ]] && usage
case "$1" in
  pick)       shift; cmd_pick "$@" ;;
  send)       shift; cmd_send "$@" ;;
  categories) cmd_categories ;;
  -h|--help)  usage ;;
  *)          echo "Unknown command: $1" >&2; usage ;;
esac
