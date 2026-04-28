# ClawLinks Skill

A portable, self-contained link manager with a beautiful static web UI.

## What's inside

- `SKILL.md` — skill definition
- `scripts/clawlinks.sh` — all logic (bash + embedded Python for JSON/HTML gen)

## Setup

```bash
# Choose where your links data lives
export CLAWLINKS_DIR="$HOME/.clawlinks"   # or any path you like

# Initialize data file if needed
mkdir -p "$CLAWLINKS_DIR"
[[ -f "$CLAWLINKS_DIR/links.json" ]] || echo '[]' > "$CLAWLINKS_DIR/links.json"
```

## Usage

```bash
# Add a link
bash scripts/clawlinks.sh save "https://example.com" "Example Site"

# Tag it
bash scripts/clawlinks.sh topic "https://example.com" "Reference"

# List topics
bash scripts/clawlinks.sh topics

# Generate the HTML site
bash scripts/clawlinks.sh generate

# Open it
open "$CLAWLINKS_DIR/index.html"   # macOS
# or xdg-open on Linux
```

## Deploy to GitHub Pages

```bash
# 1. Create a GitHub repo (e.g., clawlinks)
# 2. Clone it locally to ~/clawlinks-site
git clone git@github.com:<you>/clawlinks.git ~/clawlinks-site

# 3. After each generate:
cp "$CLAWLINKS_DIR/index.html" ~/clawlinks-site/
cd ~/clawlinks-site
git add index.html
git commit -m "chore: update links — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
git push
```

Your site goes live at `https://<you>.github.io/clawlinks/`

## Notes

- The delete button on the site copies `remove <url>` to clipboard and opens the ClawLinks Telegram channel. Change `CHANNEL_INVITE` inside the `generate` block if you want a different destination.
- The script is portable — just set `CLAWLINKS_DIR` and you're good.
