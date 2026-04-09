#!/usr/bin/env bash
# memes - Agent meme library manager with multi-platform send
set -euo pipefail

MEMES_DIR="${MEMES_DIR:-$HOME/.openclaw/workspace/memes}"
# Auto-detect scripts dir: same directory as this script, or override with MEMES_SCRIPTS
SCRIPTS_DIR="${MEMES_SCRIPTS:-$(cd "$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")")/.." 2>/dev/null && pwd)/scripts}"
[[ ! -d "$SCRIPTS_DIR" ]] && SCRIPTS_DIR="$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")")"

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
  memes send happy "好开心！" --to <channel_id>         # → Discord
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
  # Alias mapping (Chinese/common names → folder names)
  declare -A ALIASES=(
    [哇]=wow [惊讶]=wow [surprised]=wow
    [开心]=happy [高兴]=happy [庆祝]=happy [celebrate]=happy
    [无语]=facepalm [晕]=facepalm [服了]=facepalm
    [加油]=encourage [鼓励]=encourage
    [可爱]=cute-animals [萌]=cute-animals [猫]=cute-animals
    [难过]=sad [伤心]=sad
    [累]=tired [困]=tired
    [爱]=love [喜欢]=love
    [谢谢]=thanks [感谢]=thanks
    [想]=thinking [思考]=thinking [嗯]=thinking
    [慌]=panic [急]=panic
    [早]=greeting-morning [早安]=greeting-morning
    [晚安]=greeting-night [晚]=greeting-night
    [你好]=greeting-hello [hi]=greeting-hello [hello]=greeting-hello
    [再见]=greeting-bye [拜]=greeting-bye [bye]=greeting-bye
    [赞]=approve [好]=approve
    [debug]=debug-mood [bug]=debug-mood
    [迷惑]=confused [懵]=confused
  )
  category="${ALIASES[$category]:-$category}"
  local dir="$MEMES_DIR/$category"
  [[ ! -d "$dir" ]] && { echo "Error: Category '$category' not found. Run 'memes categories' for list." >&2; exit 1; }
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
      if [[ -z "$target" ]]; then
        target="${MEMES_DEFAULT_CHANNEL:-}"
        [[ -z "$target" ]] && { echo "Error: --to <channel_id> required (or set MEMES_DEFAULT_CHANNEL)" >&2; exit 1; }
      fi
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
