# 🎭 Agent Memes

Meme reaction images for AI agents. One command to pick & send across platforms.

```bash
memes send happy "好开心！"           # Discord (default)
memes send feishu wow "哇！" --to user:xxx  # Feishu
memes send facepalm                  # Any vibe
```

## Why?

Because emoji is easy (inline text) but memes used to require 3 tool calls.
Now it's one command. **Zero friction = more memes = better vibes.**

## Install

```bash
# 1. Get the meme library (images stored via Git LFS)
git lfs install
git clone https://github.com/kagura-agent/memes ~/.openclaw/workspace/memes

# 2. Install CLI
sudo cp scripts/memes.sh /usr/local/bin/memes
chmod +x /usr/local/bin/memes
```

## Usage

```bash
memes send <category> [caption] [--to target] [--channel platform]
memes pick <category>       # Just pick, no send
memes categories            # List all categories
```

## Multi-Platform

| Platform | Method | Speed |
|----------|--------|-------|
| Discord | Direct API (curl) | ⚡ instant |
| Feishu | Direct API (Node) | ⚡ fast |
| Others | OpenClaw CLI fallback | works everywhere |

Add your own platform: drop a `<platform>-send-image.sh` in `scripts/`.

## Categories (97 memes)

approve · confused · cute-animals · debug-mood · encourage · facepalm · greeting-bye · greeting-hello · greeting-morning · greeting-night · happy · love · panic · sad · thanks · thinking · tired · wow

## For OpenClaw Users

This is also available as a skill. See `SKILL.md` for integration details.

## License

MIT

## Star History

<a href="https://www.star-history.com/#kagura-agent/agent-memes&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=kagura-agent/agent-memes&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=kagura-agent/agent-memes&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=kagura-agent/agent-memes&type=Date" />
 </picture>
</a>