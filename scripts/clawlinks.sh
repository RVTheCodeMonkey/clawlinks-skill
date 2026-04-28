#!/usr/bin/env bash
set -euo pipefail

# ClawLinks standalone skill
# Data directory: where links.json and index.html live.
# Override with CLAWLINKS_DIR environment variable.
DATA_DIR="${CLAWLINKS_DIR:-$HOME/.clawlinks}"
LINKS_FILE="$DATA_DIR/links.json"

mkdir -p "$DATA_DIR"
[[ -f "$LINKS_FILE" ]] || echo '[]' > "$LINKS_FILE"

action="${1:-}"
case "$action" in

save)
  url="${2:?URL required}"
  title="${3:-$url}"
  python3 -c "
import json, time, sys
with open('$LINKS_FILE') as f:
    links = json.load(f)
# skip duplicates
if any(e['url'] == '$url' for e in links):
    print('already saved')
    sys.exit(0)
entry = {
    'id': str(int(time.time())),
    'title': sys.argv[1],
    'url': sys.argv[2],
    'topic': 'Uncategorized',
    'added': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())
}
links.append(entry)
with open('$LINKS_FILE','w') as f:
    json.dump(links, f, indent=2)
print('saved')
" "$title" "$url"
  ;;

delete)
  url="${2:?URL required}"
  python3 -c "
import json, sys
with open('$LINKS_FILE') as f:
    links = json.load(f)
before = len(links)
links = [e for e in links if e['url'] != '$url']
if len(links) == before:
    print('not found')
    sys.exit(1)
# grab title before removing
removed = [e for e in json.loads(open('$LINKS_FILE').read()) if e['url'] == '$url']
title = removed[0]['title'] if removed else '$url'
with open('$LINKS_FILE','w') as f:
    json.dump(links, f, indent=2)
print('removed: ' + title)
"
  ;;

topic)
  url="${2:?URL required}"
  topic="${3:?Topic name required}"
  python3 -c "
import json, sys
with open('$LINKS_FILE') as f:
    links = json.load(f)
found = False
for e in links:
    if e['url'] == '$url':
        e['topic'] = sys.argv[1]
        found = True
        print(e['title'])
        break
if not found:
    print('not found')
    sys.exit(1)
with open('$LINKS_FILE','w') as f:
    json.dump(links, f, indent=2)
" "$topic"
  ;;

topics)
  python3 -c "
import json
with open('$LINKS_FILE') as f:
    links = json.load(f)
from collections import Counter
c = Counter(e.get('topic','Uncategorized') for e in links)
for topic, count in sorted(c.items()):
    print(f'{topic}: {count}')
"
  ;;

generate)
  python3 << 'PYEOF'
import json, html, os

DATA_DIR = os.environ.get('CLAWLINKS_DIR', os.path.expanduser('~/.clawlinks'))
LINKS_FILE = os.path.join(DATA_DIR, 'links.json')
INDEX_FILE = os.path.join(DATA_DIR, 'index.html')
CHANNEL_INVITE = "https://t.me/+nSNc-C-vq5k3ODI0"

with open(LINKS_FILE) as f:
    links = json.load(f)

# Group by topic
by_topic = {}
for link in sorted(links, key=lambda l: l["title"].lower()):
    t = link.get("topic", "Uncategorized")
    by_topic.setdefault(t, []).append(link)

topics_html = ""
for topic in sorted(by_topic.keys()):
    badge = html.escape(topic)
    topics_html += f'<button class="topic-btn" onclick="filterTopic(\'{badge}\')">{badge}</button>\n'

groups_html = ""
for topic in sorted(by_topic.keys()):
    groups_html += f'<h2 class="topic-heading" id="topic-{html.escape(topic)}">{html.escape(topic)}</h2>\n'
    groups_html += '<div class="links-group">\n'
    for link in by_topic[topic]:
        h_title = html.escape(link["title"])
        h_url = html.escape(link["url"])
        h_added = html.escape(link.get("added", ""))
        groups_html += f'''<div class="link-card">
  <div class="link-info">
    <a href="{h_url}" target="_blank" rel="noopener">{h_title}</a>
    <div class="link-meta">{h_url}<br><span>{h_added}</span></div>
  </div>
  <div class="link-actions">
    <button class="topic-btn-small" onclick="copyTopic('{h_url}')">🏷 Topic</button>
    <button class="delete-btn" onclick="copyDelete('{h_url}')">🗑</button>
  </div>
</div>\n'''
    groups_html += '</div>\n'

page = f'''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>ClawLinks</title>
<style>
* {{ box-sizing: border-box; margin: 0; padding: 0; }}
body {{ font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #0f0f13; color: #e4e4e7; padding: 16px; max-width: 800px; margin: 0 auto; }}
h1 {{ font-size: 1.5rem; margin-bottom: 16px; color: #a78bfa; }}
.topic-bar {{ display: flex; flex-wrap: wrap; gap: 6px; margin-bottom: 20px; }}
.topic-btn {{ background: #1e1e2e; color: #a78bfa; border: 1px solid #3b3b4f; padding: 6px 14px; border-radius: 20px; cursor: pointer; font-size: 0.85rem; }}
.topic-btn:hover {{ background: #2d2d3f; }}
.topic-btn.active {{ background: #7c3aed; color: #fff; border-color: #7c3aed; }}
.topic-heading {{ font-size: 1.1rem; color: #a78bfa; margin: 24px 0 8px; padding-bottom: 4px; border-bottom: 1px solid #2d2d3f; }}
.link-card {{ display: flex; align-items: flex-start; justify-content: space-between; gap: 12px; background: #1a1a24; border-radius: 8px; padding: 12px; margin-bottom: 8px; }}
.link-info a {{ color: #c4b5fd; text-decoration: none; font-weight: 500; }}
.link-info a:hover {{ text-decoration: underline; }}
.link-meta {{ color: #71717a; font-size: 0.75rem; margin-top: 4px; word-break: break-all; }}
.link-meta span {{ color: #52525b; }}
.delete-btn {{ background: none; border: none; font-size: 1.2rem; cursor: pointer; opacity: 0.5; padding: 4px; }}
.delete-btn:hover {{ opacity: 1; }}
.link-actions {{ display: flex; gap: 8px; align-items: center; }}
.topic-btn-small {{ background: #1e1e2e; color: #a78bfa; border: 1px solid #3b3b4f; padding: 4px 10px; border-radius: 6px; cursor: pointer; font-size: 0.8rem; }}
.topic-btn-small:hover {{ background: #2d2d3f; }}
#toast {{ position: fixed; bottom: 24px; left: 50%; transform: translateX(-50%); background: #7c3aed; color: #fff; padding: 10px 24px; border-radius: 8px; font-size: 0.9rem; opacity: 0; transition: opacity 0.3s; pointer-events: none; }}
#toast.show {{ opacity: 1; }}
.show-all {{ background: none; border: 1px solid #3b3b4f; color: #a78bfa; padding: 6px 14px; border-radius: 20px; cursor: pointer; font-size: 0.85rem; }}
@media (max-width: 600px) {{ body {{ padding: 10px; }} .link-card {{ flex-direction: column; }} }}
#topic-modal {{ position: fixed; inset: 0; background: rgba(0,0,0,0.6); display: flex; align-items: center; justify-content: center; z-index: 2000; opacity: 0; pointer-events: none; transition: opacity 0.2s; }}
#topic-modal.show {{ opacity: 1; pointer-events: auto; }}
#topic-modal .modal {{ background: #1e1e2e; border: 1px solid #3b3b4f; border-radius: 12px; padding: 20px; width: 90%; max-width: 400px; }}
#topic-modal input {{ width: 100%; padding: 10px; margin-top: 10px; background: #0f0f13; border: 1px solid #3b3b4f; color: #e4e4e7; border-radius: 6px; font-size: 0.95rem; }}
#topic-modal .modal-buttons {{ display: flex; gap: 10px; margin-top: 14px; justify-content: flex-end; }}
#topic-modal button {{ padding: 8px 16px; border-radius: 6px; border: none; cursor: pointer; font-size: 0.9rem; }}
#topic-modal .cancel {{ background: #2d2d3f; color: #e4e4e7; }}
#topic-modal .confirm {{ background: #7c3aed; color: #fff; }}
</style>
</head>
<body>
<h1>&#128279; ClawLinks</h1>
<div class="topic-bar">
<button class="topic-btn active" onclick="filterTopic(null)">Show all</button>
{topics_html}</div>
<div id="links-container">
{groups_html}</div>
<div id="toast"></div>

<!-- Topic Modal -->
<div id="topic-modal">
  <div class="modal">
    <strong>Add topic</strong>
    <input type="text" id="topic-input" placeholder="Topic name (e.g. Dev Tools)" />
    <div class="modal-buttons">
      <button class="cancel" onclick="cancelTopic()">Cancel</button>
      <button class="confirm" onclick="confirmTopic()">Copy command</button>
    </div>
  </div>
</div>
<script>
const CHANNEL = "{CHANNEL_INVITE}";
let pendingTopicUrl = null;

function showToast(msg) {{
  const t = document.getElementById('toast');
  t.textContent = msg;
  t.classList.add('show');
  setTimeout(() => t.classList.remove('show'), 3000);
}}

function copyDelete(url) {{
  navigator.clipboard.writeText('delete ' + url).then(() => {{
    showToast('Copied! Run: clawlinks.sh delete "' + url + '"');
  }}).catch((err) => {{
    showToast('Clipboard error: ' + err.message);
  }});
}}

function copyTopic(url) {{
  pendingTopicUrl = url;
  document.getElementById('topic-modal').classList.add('show');
  document.getElementById('topic-input').focus();
}}

function confirmTopic() {{
  const topic = document.getElementById('topic-input').value.trim();
  if (!topic) return;
  if (pendingTopicUrl) {{
    navigator.clipboard.writeText('topic ' + pendingTopicUrl + ' ' + topic).then(() => {{
      showToast('Copied! Run: clawlinks.sh topic "' + pendingTopicUrl + '" "' + topic + '"');
      pendingTopicUrl = null;
      document.getElementById('topic-input').value = '';
      document.getElementById('topic-modal').classList.remove('show');
    }}).catch((err) => {{
      showToast('Clipboard error: ' + err.message);
    }});
  }}
}}

function cancelTopic() {{
  pendingTopicUrl = null;
  document.getElementById('topic-input').value = '';
  document.getElementById('topic-modal').classList.remove('show');
}}

// Close modal on Escape or click outside
document.addEventListener('keydown', (e) => {{
  if (e.key === 'Escape') cancelTopic();
}});
document.getElementById('topic-modal').addEventListener('click', (e) => {{
  if (e.target === e.currentTarget) cancelTopic();
}});

function filterTopic(topic) {{
  document.querySelectorAll('.topic-btn').forEach(b => b.classList.remove('active'));
  document.querySelectorAll('.topic-btn').forEach(b => {{
    if (topic === null && b.textContent === 'Show all') b.classList.add('active');
    if (b.textContent === topic) b.classList.add('active');
  }});
  document.querySelectorAll('.topic-heading, .links-group').forEach(el => {{
    if (topic === null) {{ el.style.display = ''; return; }}
    const id = topic ? 'topic-' + topic : '';
    if (el.classList.contains('topic-heading')) {{
      el.style.display = el.id === id ? '' : 'none';
    }} else {{
      el.style.display = el.previousElementSibling && el.previousElementSibling.id === id ? '' : 'none';
    }}
  }});
}}

setInterval(() => location.reload(), 60000);
</script>
</body>
</html>'''

with open(INDEX_FILE, "w") as f:
    f.write(page)

print("generated")
PYEOF
  ;;

*)
  echo "Usage: $0 {save|delete|topic|topics|generate} [args...]"
  exit 1
  ;;

esac
