---
name: clawlinks
description: >
  Manage a shared link collection with a static web UI.
  Portable version of the ClawLinks skill — works standalone or inside OpenClaw.
  Supports save/delete/topic/topics/generate, auto-generates a searchable HTML page.
---

# ClawLinks Skill (Standalone)

Self-contained link manager with a beautiful dark-mode static site. Perfect for sharing curated resources.

## Files

- `scripts/clawlinks.sh` — main CLI
- Data dir (default: `~/.clawlinks/`):
  - `links.json` — stored links
  - `index.html` — generated static site

## Quick Start

```bash
# 1. Clone/copy this skill somewhere
cd clawlinks-skill

# 2. Pick a data directory (optional)
export CLAWLINKS_DIR="$HOME/my-links"   # defaults to ~/.clawlinks

# 3. Add a link
bash scripts/clawlinks.sh save "https://example.com" "Example Site"

# 4. Generate the HTML
bash scripts/clawlinks.sh generate

# 5. Open the site
open "$CLAWLINKS_DIR/index.html"   # or xdg-open on Linux
```

## Commands

All commands go through the script:

| Command | Purpose |
|---|---|
| `save <url> [title]` | Add a new link (auto-fetches title if omitted) |
| `delete <url>` | Remove a link by URL |
| `topic <url> <topic>` | Tag a link with a topic |
| `topics` | List all topics and counts |
| `generate` | Rebuild `index.html` from `links.json` |

**Examples:**
```bash
bash scripts/clawlinks.sh save "https://github.com" "GitHub"
bash scripts/clawlinks.sh topic "https://github.com" "Dev Tools"
bash scripts/clawlinks.sh topics
bash scripts/clawlinks.sh delete "https://spam.link"
```

## Data Format

`links.json` is a simple array:

```json
[
  {
    "id": "1714321023",
    "title": "Example",
    "url": "https://example.com",
    "topic": "General",
    "added": "2026-04-28T10:00:00Z"
  }
]
```

## HTML Site

The generated `index.html` is:
- Single-file, zero dependencies
- Dark theme, filterable by topic
- Each card has a 🗑 button — copies `remove <url>` to clipboard and opens the ClawLinks channel (configurable inside the script via `CHANNEL_INVITE`)
- Auto-reloads every 60s (change in the Python gen block)

## Integration with OpenClaw (original use-case)

Inside an OpenClaw skill, you'd call:

```bash
export CLAWLINKS_DIR="/root/.openclaw/workspace/clawlinks"
bash /path/to/clawlinks.sh save "$url" "$title"
bash /path/to/clawlinks.sh generate
# then git commit/push to GitHub Pages if needed
```

## GitHub Pages Deployment

1. Create a GitHub repo (e.g., `yourname/clawlinks`)
2. Enable Pages (Settings → Pages → Source: `main` branch `/`)
3. Clone it somewhere, then after each `generate`:
   ```bash
   cp "$CLAWLINKS_DIR/index.html" /path/to/clawlinks-site/
   cd /path/to/clawlinks-site
   git add index.html && git commit -m "chore: update links — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
   git push
   ```
4. Your site goes live at `https://<user>.github.io/clawlinks/`

## Customization

- **Data directory:** set `CLAWLINKS_DIR` environment variable before calling the script
- **Channel invite link:** edit `CHANNEL_INVITE` in the `generate` block
- **Auto-reload interval:** change `setInterval(() => location.reload(), 60000)` in the generated HTML (milliseconds)

## License

MIT — do what you want with it.
