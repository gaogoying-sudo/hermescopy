---
name: hermes-dashboard-building
description: Build a web-based management dashboard for Hermes Agent — Python HTTP backend + single-file HTML frontend for viewing/editing memory, config, skills, profiles, sessions, cron jobs, and real-time chat with conversation management. Includes patterns for importing existing Hermes sessions as conversations, JS syntax debugging with node -c, and macOS LaunchAgent auto-start.
tags: [hermes, dashboard, web, admin, management, memory, config]
created: 2026-04-22
---

# Hermes Dashboard Building

## When to Use
- Need a visual interface to manage Hermes Agent internals
- Want to view/edit MEMORY.md, USER.md, config.yaml from a browser
- Need to browse skills, profiles, sessions, cron jobs visually
- Want real-time chat with Hermes Agent via web interface
- Need conversation history with WeChat-style sidebar (create, switch, rename, delete)
- Building admin tools for Hermes-based systems

## Architecture

```
hermes-dashboard/
├── server.py    # Python HTTP backend (no frameworks needed)
└── index.html   # Single-file HTML frontend (Tailwind CSS CDN)
```

### Backend (server.py)
- Pure Python `http.server` — zero dependencies beyond `pyyaml`
- REST API under `/api/*` endpoints
- Serves static `index.html` from same directory
- Security: file access restricted to `~/.hermes/` only
- Runs on `127.0.0.1:9863` by default

### Frontend (index.html)
- Single HTML file, no build step
- Tailwind CSS via CDN
- Vanilla JavaScript, no frameworks
- Pages: Dashboard, Memory Editor, Config Editor, Skills Browser, Profiles, Sessions, Cron

## Setup

```bash
# Install dependency
pip3 install pyyaml

# Create project directory
mkdir -p ~/Projects/hermes-dashboard && cd ~/Projects/hermes-dashboard

# Create server.py and index.html (see below)

# Start server
python3 server.py
# Visit http://127.0.0.1:9863
```

### API Endpoints
| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | /api/stats | Dashboard overview stats |
| GET | /api/memory | Read MEMORY.md + USER.md |
| POST | /api/memory | Write MEMORY.md + USER.md |
| GET | /api/memory/suggestions | Analyze memory for optimization |
| GET | /api/config | Read config.yaml (raw + parsed) |
| POST | /api/config | Write config.yaml |
| GET | /api/skills | List all skills with descriptions |
| GET | /api/sessions | List session files (sorted by mtime) |
| GET | /api/session?name=X | Read session content |
| GET | /api/profiles | List profiles + AGENTS.md content |
| POST | /api/profiles | Write profile files |
| GET | /api/cron | List cron jobs |
| POST | /api/cron | Create cron job (via hermes CLI) |
| DELETE | /api/cron/X | Delete cron job |
| GET | /api/file?path=X | Read arbitrary file (restricted to ~/.hermes) |
| GET | /api/chat/history | Recent session summaries |
| GET/POST | /api/conversations | List / Create conversations |
| GET | /api/conversations/{id} | Get conversation detail |
| POST | /api/conversations/{id}/rename | Rename conversation |
| POST | /api/conversations/{id}/message | Add message to conversation |
| PUT | /api/conversations/{id} | Update conversation |
| DELETE | /api/conversations/{id} | Delete conversation |
| POST | /api/chat | Send message (via Hermes CLI subprocess) |
| GET | /api/status | Dashboard server health check |

## Key Patterns

### 1. Security: Path Restriction
```python
full = Path(filepath).expanduser()
if not str(full).startswith(str(HERMES_DIR)):
    self._send_json({"error": "Access denied"}, 403)
    return
```

### 2. Static File Serving
```python
if path == "/" or path == "/index.html":
    html_file = Path(__file__).parent / "index.html"
    self.send_response(200)
    self.send_header("Content-Type", "text/html; charset=utf-8")
    self.end_headers()
    self.wfile.write(html_file.read_bytes())
    return
```

### 3. Memory Analysis
Parse MEMORY.md sections (split by `\n§\n`), detect completed projects, overlong entries (>500 chars), total usage vs limits.

### 4. Cron Job Proxy
```python
subprocess.run(["hermes", "cron", "create", "--schedule", schedule, "--prompt", prompt], capture_output=True, text=True)
```

## Common Pitfalls

1. **CRITICAL: Hermes Gateway has NO HTTP API port** — Gateway manages messaging platforms (Feishu, Telegram, WhatsApp) but does NOT expose a REST API. Do NOT try to `fetch('http://127.0.0.1:14863/api/chat')`. Instead, add a `/api/chat` endpoint to the dashboard server itself that calls `hermes chat -q "message" -Q --source dashboard` via subprocess.

2. **Port conflicts** — Dashboard uses 9863. Kill existing process before starting: `lsof -ti:9863 | xargs kill -9`

3. **pyyaml dependency** — Install with `pip3 install pyyaml` if not already installed.

4. **Memory char limits** — MEMORY.md max 2,200 chars, USER.md max 1,375 chars. Add visual warnings when approaching limits.

5. **Session files are JSON** — Each session in `~/.hermes/sessions/` is a JSON file with `messages` array. Parse carefully (may contain non-serializable content).

6. **File path security** — Only allow reading/writing files under `~/.hermes/`. Validate paths with `str(full).startswith(str(HERMES_DIR))`.

7. **Chat timeout** — Hermes CLI can take 10-60s for complex queries. Set generous timeout (120s) on subprocess.

8. **Chat output parsing** — Hermes CLI output includes `session_id: XXX` line at the end. Strip it before returning response.

## Chat API via CLI (Critical Pattern)

Since Hermes Gateway does NOT expose HTTP, the dashboard server itself must handle chat:

```python
# server.py — add to do_POST handler
elif path == "/api/chat":
    self._handle_chat(body)

# Handler implementation
def _handle_chat(self, body):
    message = body.get("message", "")
    profile = body.get("profile", "")
    cmd = ["hermes", "chat", "-q", message, "-Q", "--source", "dashboard"]
    if profile:
        cmd.extend(["--profile", profile])
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=120, cwd=str(Path.home()))
    output = result.stdout.strip()
    # Strip session_id line
    lines = output.split("\n")
    response = "\n".join(l for l in lines if not l.startswith("session_id:")).strip()
    self._send_json({"response": response, "session_id": ...})
```

Frontend calls `fetch(API + '/chat')` — NOT a separate gateway port.

## Memory Stats to Track

- `memory_chars` vs 2,200 limit → percentage + color coding (green/yellow/red)
- `user_chars` vs 1,375 limit
- `sessions` count from `~/.hermes/sessions/`
- `skills` count from `~/.hermes/skills/` directories
- `profiles` count from `~/.hermes/profiles/`
- `cron_jobs` count from `~/.hermes/cron/` JSON files

## Frontend Design Notes

- Dark theme (gray-950 background) — matches developer aesthetic
- Sidebar navigation with active state highlighting
- Stat cards with hover animation
- Progress bars for memory usage with color thresholds
- Real-time character counting in text editors
- Search/filter for skills and sessions lists

## Extended Features (v2)

### Chat Interface (Full Redesign)

Reference design: ChatGPT, Claude, Slack — modern chat UX patterns.

**Layout: Full-screen 3-zone**
```
┌─────────────────────────────────────┐
│ Chat Header (flex-shrink-0)         │  ← Agent name + profile badge + selector + new chat
├─────────────────────────────────────┤
│                                     │
│ Chat Messages (flex-1, overflow)    │  ← Welcome screen or message list
│                                     │
├─────────────────────────────────────┤
│ Chat Input (flex-shrink-0)          │  ← Auto-resize textarea + send button
└─────────────────────────────────────┘
```

**CSS Architecture (no frameworks, pure CSS):**
```css
/* Container: full viewport height, 3-zone flex layout */
.chat-container { display: flex; flex-direction: column; height: 100vh; }
.chat-header { flex-shrink: 0; padding: 12px 20px; border-bottom: 1px solid #1f2937; }
.chat-messages { flex: 1; overflow-y: auto; padding: 20px; scroll-behavior: smooth; }
.chat-input-area { flex-shrink: 0; padding: 16px 20px; border-top: 1px solid #1f2937; }

/* Message rows: avatar + bubble, user on right */
.msg-row { display: flex; gap: 12px; margin-bottom: 20px; animation: msgIn 0.25s ease; }
.msg-row.user-row { flex-direction: row-reverse; }
@keyframes msgIn { from { opacity: 0; transform: translateY(12px); } to { opacity: 1; } }

/* Avatars: gradient backgrounds */
.msg-avatar { width: 32px; height: 32px; border-radius: 8px; font-size: 16px; }
.msg-avatar.user-avatar { background: linear-gradient(135deg, #6366f1, #8b5cf6); }
.msg-avatar.agent-avatar { background: linear-gradient(135deg, #059669, #10b981); }

/* Bubbles: rounded corners (directional) */
.msg-bubble { max-width: 75%; min-width: 60px; }
.msg-bubble.user-bubble { background: #4f46e5; border-radius: 16px 16px 4px 16px; }
.msg-bubble.agent-bubble { background: #1e293b; border-radius: 16px 16px 16px 4px; }

/* Typing indicator: 3 animated dots */
.typing-dots span { width: 6px; height: 6px; border-radius: 50%; background: #6b7280;
  animation: dotPulse 1.4s infinite ease-in-out; }
@keyframes dotPulse { 0%,80%,100% { transform:scale(0.6);opacity:0.4; } 40% { transform:scale(1);opacity:1; } }

/* Welcome screen: centered with quick action pills */
.welcome-screen { display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100%; }
.quick-action-btn { background: #1e293b; border: 1px solid #374151; border-radius: 12px; padding: 10px 16px; }
.quick-action-btn:hover { border-color: #6366f1; }

/* Input: auto-resize textarea */
.chat-textarea { width: 100%; min-height: 44px; max-height: 200px; resize: none; }
.send-btn { width: 40px; height: 40px; border-radius: 10px; }
.send-btn:disabled { opacity: 0.5; cursor: not-allowed; }

/* Copy on hover */
.msg-actions { opacity: 0; transition: opacity 0.15s; }
.msg-row:hover .msg-actions { opacity: 1; }
```

**JavaScript Architecture:**
```javascript
const PROFILES = {
  '': { icon: '🤖', name: '默认', color: '#6366f1' },
  'daguanjia': { icon: '🏠', name: '大管家', color: '#6366f1' },
  'goudan': { icon: '🐕', name: '狗蛋', color: '#f59e0b' },
  'xiaochu': { icon: '👨‍🍳', name: '小厨', color: '#10b981' },
};

let conversationHistory = []; // Stores {role, content, ts} for context
let isStreaming = false;      // Prevent double-sends

// Auto-resize textarea as user types
function autoResize(el) {
  el.style.height = 'auto';
  el.style.height = Math.min(el.scrollHeight, 200) + 'px';
  document.getElementById('send-btn').disabled = !el.value.trim();
}

// Handle Enter/Shift+Enter
function handleChatKey(e) {
  if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); sendChat(); }
}

// Add message to DOM (with animation)
function addMessage(role, content, timestamp) {
  const isUser = role === 'user';
  const p = PROFILES[document.getElementById('chat-profile').value] || PROFILES[''];
  // Insert msg-row with avatar, bubble, timestamp, copy button
  // Remove welcome screen if present
  // Store in conversationHistory for context
  // Scroll to bottom
}

// Typing indicator with animated dots
function addTypingIndicator() { /* insert animated dots */ }
function removeTypingIndicator() { /* remove */ }

// Markdown rendering (basic)
function renderMarkdown(text) {
  let html = escapeHtml(text);
  html = html.replace(/```(\w*)\n([\s\S]*?)```/g, '<pre><code>$2</code></pre>');
  html = html.replace(/`([^`]+)`/g, '<code>$1</code>');
  html = html.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');
  html = html.replace(/\n\n/g, '</p><p>');
  html = '<p>' + html.replace(/\n/g, '<br>') + '</p>';
  return html;
}

// Send message to Dashboard Chat API (NOT gateway — gateway has no HTTP API!)
async function sendChat() {
  if (isStreaming) return;
  const msg = input.value.trim(); if (!msg) return;
  isStreaming = true;
  addMessage('user', msg);
  addTypingIndicator();

  try {
    const resp = await fetch(API + '/chat', {
      method: 'POST',
      body: JSON.stringify({ message: msg, profile, history: conversationHistory.slice(-10) })
    });
    removeTypingIndicator();
    const data = await resp.json();
    if (data.response) addMessage('assistant', data.response);
  } catch(e) {
    removeTypingIndicator();
    addMessage('assistant', `❌ **连接失败**: ${e.message}`);
  }
  isStreaming = false;
}

// Dashboard status detection (gateway has no HTTP API, check dashboard server)
async function checkGatewayStatus() {
  try {
    await fetch(API + '/status', { signal: AbortSignal.timeout(2000) });
    // Show connected
  } catch(e) {
    // Show disconnected
  }
}
```

**Key UX Patterns Applied:**
1. **Welcome screen** — Empty state with quick actions (like ChatGPT/Claude)
2. **Directional bubbles** — User right (purple), Agent left (dark), directional corner radius
3. **Avatar gradients** — Visual identity per role
4. **Typing animation** — 3 pulsing dots, not static "thinking..." text
5. **Auto-resize input** — Textarea grows with content, max 200px
6. **Enter to send** — Standard chat shortcut, Shift+Enter for newline
7. **Copy on hover** — 📋 button appears on message hover
8. **Markdown rendering** — Code blocks, bold, italic, line breaks
9. **Conversation context** — Sends last 10 messages for continuity
10. **Gateway detection** — Auto-check on page load, show status
11. **Send button state** — Disabled when empty, enabled when text present
12. **New conversation** — Reset to welcome screen, clear history
13. **Message animations** — Fade-in + slide-up for new messages

**Pitfalls:**
1. **innerHTML += is slow** — Use `insertAdjacentHTML('beforeend', html)` instead
2. **Scroll to bottom** — Must scroll AFTER inserting, not before
3. **Enter key conflict** — Textarea needs `e.preventDefault()` on Enter to avoid newline
4. **Auto-resize** — Set `height: 'auto'` first, then measure `scrollHeight`
5. **Gateway has no HTTP API** — Never try to connect to gateway port 14863 for chat; use dashboard's own `/api/chat` endpoint

### Memory Analysis/Suggestions
- Parse MEMORY.md sections (split by `\n§\n`)
- Detect completed projects (regex: `阶段.*完成|已完成|Done|completed`)
- Flag overlong entries (>500 chars)
- Check total usage vs limits (2200 + 1375 chars)
- Return suggestions with levels: warning/info/tip

### Session Detail Viewing
- Modal overlay showing last 20 messages
- Role-based coloring (user=indigo, assistant=emerald)
- Content truncated to 500 chars per message

### Profile Editor
- Inline textarea for AGENTS.md per profile
- Save button per profile
- POST to `/api/profiles` with `{profile, file, content}`

### Cron Job Management
- Create modal with name/schedule/prompt fields
- Delete button per job
- Proxy to `hermes cron create/remove` CLI via subprocess

### Conversation Management (v2)

#### Architecture: File-based conversation storage
```
hermes-dashboard/
├── server.py
├── index.html
└── conversations/          # JSON files, one per conversation
    ├── 20260422_182313_946cca.json
    └── ...
```

Each conversation JSON:
```json
{
  "id": "20260422_182313_946cca",
  "name": "对话名称",
  "profile": "daguanjia",
  "messages": [{"role": "user", "content": "...", "ts": "2026-04-22T18:23:13"}],
  "last_message": "最后一条消息预览",
  "created_at": "2026-04-22T18:23:13",
  "updated_at": "2026-04-22T18:23:13"
}
```

#### API Endpoints
| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | /api/conversations | List all (sorted by mtime desc) |
| GET | /api/conversations/{id} | Get conversation detail |
| POST | /api/conversations | Create new conversation |
| POST | /api/conversations/{id}/rename | Rename conversation |
| POST | /api/conversations/{id}/message | Add message to conversation |
| PUT | /api/conversations/{id} | Update conversation (name/profile) |
| DELETE | /api/conversations/{id} | Delete conversation |

#### Path Parsing: Use Length-Based Routing
**Pitfall:** Don't use `path.split("/")[-1]` to extract conv_id — it breaks for sub-paths like `/api/conversations/{id}/rename`.

**Correct approach:** Use path segment count:
```python
parts = path.split("/")
# /api/conversations/{id} → ['', 'api', 'conversations', '{id}'] → len=4
# /api/conversations/{id}/rename → ['', 'api', 'conversations', '{id}', 'rename'] → len=5
if len(parts) == 4:
    conv_id = parts[3]
    # handle GET/PUT/DELETE on conversation
elif len(parts) == 5:
    conv_id = parts[3]
    action = parts[4]  # 'rename', 'message', etc.
    # handle sub-actions
```

#### Chat API Integration
The `/api/chat` handler saves messages to the active conversation:
```python
def _handle_chat(self, body):
    conv_id = body.get("conversation_id", "")
    if conv_id:
        _add_message(conv_id, "user", body["message"])
    # ... call hermes CLI ...
    if conv_id and response:
        _add_message(conv_id, "assistant", response)
```

#### Auto-Create Conversation
When user sends first message with no active conversation:
```javascript
if (!currentConvId) {
  const data = await apiPost('/conversations', {
    name: msg.substring(0, 30) + (msg.length > 30 ? '...' : ''),
    profile
  });
  currentConvId = data.id;
  loadConversations();
}
```

#### Conversation List Sidebar (WeChat-style)
Right sidebar (w-72) with scrollable card list:
```html
<div id="convo-sidebar" class="w-72 bg-gray-900 border-l border-gray-800 flex flex-col">
  <div class="p-3 border-b">
    <span>💬 对话列表</span>
    <span id="convo-count">0 个对话</span>
  </div>
  <div id="convo-list" class="flex-1 overflow-y-auto p-2 space-y-1.5">
    <!-- Cards rendered here -->
  </div>
</div>
```

Card design per conversation:
```html
<div class="convo-card bg-gray-800 hover:bg-gray-750 rounded-lg p-3 cursor-pointer
            border border-transparent" onclick="switchConversation('{id}')">
  <div class="flex items-center gap-2 mb-1.5">
    <div class="w-6 h-6 rounded-md" style="background:{color}20;color:{color}">{icon}</div>
    <div class="flex-1 min-w-0">
      <div class="text-xs font-semibold text-white truncate">{name}</div>
    </div>
    <span class="text-[9px] bg-gray-700 text-gray-400 px-1.5 py-0.5 rounded-full">{count}</span>
    <button onclick="deleteConversation('{id}')">🗑</button>
  </div>
  <div class="text-[10px] text-gray-500 truncate">{preview}</div>
  <div class="text-[9px] text-gray-600">{time}</div>
</div>
```

Active state: `border-indigo-500/50` + `bg-gray-800`

#### Layout Change: 3-Zone + Sidebar
```
┌────────────────────────────────────────────┬──────────┐
│ Chat Header (agent avatar + title + badge) │ 对话列表  │
├────────────────────────────────────────────┤          │
│                                            │          │
│ Chat Messages (flex-1, overflow)           │ Cards    │
│                                            │ (scroll) │
│                                            │          │
├────────────────────────────────────────────┤          │
│ Chat Input (textarea + send)               │          │
└────────────────────────────────────────────┴──────────┘
```

Container: `flex-direction: row` (not column). Main chat area is `flex-1`, sidebar is `w-72 flex-shrink-0`.

### Critical JS Bug: Backtick in Regex
**Symptom:** Page loads blank, `showPage is not defined`, `typeof loadStats === 'undefined'`. No console errors.

**Root Cause:** A backtick `` ` `` inside a regex pattern inside a `<script>` tag breaks the HTML parser. The browser sees the backtick as closing a template literal that was never opened, causing a syntax error that silently fails the entire script block.

**Example of broken code:**
```javascript
html = html.replace(/`([^`]+)`/g, '<code>$1</code>');
//                     ^ This backtick breaks the HTML parser
```

**Fix:** Use hex escape `\x60` instead:
```javascript
html = html.replace(/\x60([^\x60]+)\x60/g, '<code>$1</code>');
```

**Detection:** Count backticks in the script content — must be even. If odd, there's an unclosed template literal.

**Why no console error?** The HTML parser may split the script tag at the backtick, creating two malformed script tags. The browser silently fails both.

### Critical JS Bug #2: Quote Conflict in Inline onclick
**Symptom:** Same as above — blank page, functions undefined, no console errors.

**Root Cause:** `onclick="quickSend('你好...')"` inside a template literal or single-quoted string creates unbalanced quotes. The inner single quotes close the outer string prematurely.

**Broken:**
```javascript
el.innerHTML = `<button onclick="quickSend('你好')">click</button>`;
//                                    ^ closes the string
```

**Fix:** Use HTML entities for inner quotes:
```javascript
el.innerHTML = `<button onclick="quickSend(&#x27;你好&#x27;)">click</button>`;
```

**Detection:** Use Node.js syntax check: `node -c /tmp/script.js` — catches all JS syntax errors including quote conflicts.

**Debug workflow:**
1. Extract JS from HTML: `grep -oP '(?<=<script>).*?(?=</script>)' index.html > /tmp/test.js`
2. Validate: `node -c /tmp/test.js`
3. Fix reported errors, repeat

### Importing Existing Hermes Sessions as Conversations

When building the dashboard on an existing Hermes install, import historical sessions:

```python
import json
from pathlib import Path
from datetime import datetime

sessions_dir = Path.home() / '.hermes' / 'sessions'
conv_dir = Path('conversations')  # dashboard conversation storage
conv_dir.mkdir(parents=True, exist_ok=True)

for f in sessions_dir.glob('*.json'):
    data = json.loads(f.read_text())
    messages = data.get('messages', [])
    
    # Filter to user/assistant messages only
    filtered = []
    for m in messages:
        role = m.get('role', '')
        content = m.get('content', '')
        if role in ('user', 'assistant') and content:
            # Handle content as array (some sessions use this format)
            if isinstance(content, list):
                content = ' '.join(p.get('text', '') for p in content if isinstance(p, dict) and p.get('type') == 'text')
            if content.strip():
                filtered.append({'role': role, 'content': content, 'ts': data.get('last_updated', '')})
    
    if not filtered:
        continue
    
    # First user message becomes conversation name
    user_msgs = [m for m in filtered if m['role'] == 'user']
    name = (user_msgs[0]['content'][:30] + '...') if user_msgs else '未命名对话'
    
    # Infer profile from system prompt
    profile = ''
    sys_prompt = data.get('system_prompt', '')
    if '小厨' in sys_prompt or '小强' in sys_prompt:
        profile = 'xiaochu'
    elif '狗蛋' in sys_prompt:
        profile = 'goudan'
    elif '大管家' in sys_prompt:
        profile = 'daguanjia'
    
    conv_data = {
        'id': f.stem.replace('session_', ''),
        'name': name,
        'profile': profile,
        'messages': filtered,
        'last_message': filtered[-1]['content'][:200],
        'created_at': data.get('session_start', ''),
        'updated_at': data.get('last_updated', ''),
    }
    (conv_dir / f'{conv_data["id"]}.json').write_text(json.dumps(conv_data, ensure_ascii=False, indent=2))
```

**Key considerations:**
- Session content may be a string OR an array of `{type, text}` objects — handle both
- Cron jobs have `[SYSTEM: ...]` as first message — rename these to avoid ugly conversation names
- System prompt contains role identity keywords — use for profile inference
- Skip sessions with no user/assistant messages (system-only sessions)

### Conversation Consolidation (Deduplication & Topic Grouping)

**Problem:** Hermes creates a new session file for every conversation restart, leading to 100+ fragmented conversations with the same topic (e.g., 23x "小厨上线", 14x "大管家出来").

**Solution: Topic-based grouping + message deduplication**

```python
from collections import Counter, defaultdict

# Step 1: Group by topic (first 15 chars of first user message, normalized)
topic_groups = defaultdict(list)
for f in conv_dir.glob('*.json'):
    data = json.loads(f.read_text())
    msgs = data.get('messages', [])
    user_msgs = [m for m in msgs if m['role'] == 'user']
    if user_msgs:
        first = user_msgs[0]['content']
        # Normalize to topic key
        if '小厨' in first and '上线' in first:
            topic = '小厨上线'
        elif '大管家' in first:
            topic = '大管家'
        elif '飞书' in first or 'openclaw' in first.lower():
            topic = '飞书集成'
        # ... more patterns ...
        else:
            topic = first[:15]
        topic_groups[topic].append(data)

# Step 2: Merge each group (deduplicate by content hash)
for topic, convs in topic_groups.items():
    convs.sort(key=lambda x: x.get('created_at', ''))
    all_msgs = []
    seen = set()
    for c in convs:
        for m in c.get('messages', []):
            content_hash = hash(m.get('content', '')[:50] + m.get('role', ''))
            if content_hash not in seen:
                seen.add(content_hash)
                all_msgs.append(m)
    
    # Save merged conversation
    merged = {
        'id': f'merged_{topic.replace(" ", "_")}',
        'name': user_msgs[0]['content'][:30] + '...',
        'profile': convs[0].get('profile', ''),
        'messages': all_msgs,
        'last_message': all_msgs[-1]['content'][:200],
        'created_at': convs[0].get('created_at', ''),
        'updated_at': convs[-1].get('updated_at', ''),
    }
    (conv_dir / f'merged_{topic.replace(" ", "_")}.json').write_text(json.dumps(merged, ensure_ascii=False, indent=2))
```

**Result:** 132 fragmented → 29 consolidated conversations (78% reduction).

### Extracting Feishu Conversations from Gateway Logs

**Critical:** Hermes Gateway processes Feishu messages in real-time and does NOT persist them as session files. To recover Feishu conversations, parse the gateway log.

```python
import re
from pathlib import Path
from collections import defaultdict

gateway_log = Path.home() / '.hermes' / 'logs' / 'gateway.log'
log_content = gateway_log.read_text()

# Parse inbound messages and responses
chat_groups = defaultdict(list)
for line in log_content.split('\n'):
    # Inbound: "inbound message: platform=feishu user=XXX chat=XXX msg='...'"
    inbound = re.search(r'inbound message: platform=feishu user=(\S+) chat=(\S+) msg=\'(.+?)\'', line)
    if inbound:
        chat_groups[inbound.group(2)].append({'role': 'user', 'content': inbound.group(3)})
    
    # Response: "response ready: platform=feishu chat=XXX time=XXXs api_calls=XXX response=XXX chars"
    response = re.search(r'response ready: platform=feishu chat=(\S+) time=(\S+)s api_calls=(\d+) response=(\d+) chars', line)
    if response:
        chat_groups[response.group(1)].append({
            'role': 'assistant',
            'content': f'[Response: {response.group(4)} chars, {response.group(3)} API calls, {response.group(2)}s]'
        })

# Create conversation for each Feishu chat
for chat_id, msgs in chat_groups.items():
    conv_data = {
        'id': f'feishu_{chat_id}',
        'name': f'飞书: {msgs[0]["content"][:30]}...',
        'profile': 'xiaochu',
        'messages': msgs,
        'last_message': msgs[-1]['content'][:200],
        'created_at': '',
        'updated_at': '',
    }
    (conv_dir / f'feishu_{chat_id}.json').write_text(json.dumps(conv_data, ensure_ascii=False, indent=2))
```

**Note:** Gateway logs only contain message text and response metadata, NOT the full agent response content. Feishu conversations in the dashboard will show `[Response: 436 chars, 1 API calls, 17.4s]` as the assistant message, not the actual response text.

### macOS Auto-Start (LaunchAgent)

### LaunchAgent plist (`~/Library/LaunchAgents/com.hermes.dashboard.plist`)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.hermes.dashboard</string>
    <key>ProgramArguments</key>
    <array>
        <string>/path/to/start-dashboard.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>WorkingDirectory</key>
    <string>/path/to/hermes-dashboard</string>
    <key>StandardOutPath</key>
    <string>/tmp/hermes-dashboard-stdout.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/hermes-dashboard-stderr.log</string>
</dict>
</plist>
```

### Start script (`start-dashboard.sh`)
```bash
#!/bin/bash
cd /path/to/hermes-dashboard
PORT=9863
PID=$(lsof -ti:$PORT 2>/dev/null)
if [ -n "$PID" ]; then kill $PID 2>/dev/null; sleep 1; fi
python3 server.py >> /tmp/hermes-dashboard.log 2>&1 &
sleep 2
open http://127.0.0.1:$PORT
```

### Load/Unload
```bash
launchctl load ~/Library/LaunchAgents/com.hermes.dashboard.plist
launchctl unload ~/Library/LaunchAgents/com.hermes.dashboard.plist
```
