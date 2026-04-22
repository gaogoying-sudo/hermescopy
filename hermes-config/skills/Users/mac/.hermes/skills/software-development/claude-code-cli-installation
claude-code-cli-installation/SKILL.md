---
name: claude-code-cli-installation
description: Install and authenticate Claude Code CLI using browser OAuth with Claude Pro/Plus subscription (no API key needed). Covers npm/Homebrew installation, auth cache clearing, and troubleshooting org vs personal account issues.
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [Claude, CLI, Installation, Authentication, OAuth, Setup]
    related_skills: [claude-code, opencode, codex]
---

# Claude Code CLI Installation & Authentication

## When to Use This Skill

User wants to install Claude Code CLI for terminal-based coding assistance with their Claude Pro/Plus subscription (browser auth, not API key).

## Prerequisites Check

```bash
# Check Node.js (required for npm install)
node --version  # Need v18+

# Check Homebrew (alternative install)
brew --version

# Check if already installed
which claude
claude --version
```

## Installation (Choose One)

### Option A: npm (Recommended - Faster, No Queue)
```bash
npm install -g @anthropic-ai/claude-code
```

### Option B: Homebrew (May Queue on Mirrors)
```bash
brew install claude-code
```

## Authentication Flow

### Step 1: Clear Old Auth (If Previously Used Claude Desktop)

```bash
# Logout CLI
claude logout 2>/dev/null || true

# Clear CLI config caches
rm -rf ~/.claude-code 2>/dev/null || true
rm -rf ~/.config/claude-code 2>/dev/null || true

# Note: ~/.claude.json is Claude Desktop config - don't delete unless user wants to reset Desktop too
```

### Step 2: Trigger Browser Auth

```bash
claude login
```

This opens browser to: `https://claude.com/cai/oauth/authorize?...`

If browser doesn't open, manually visit the URL shown in terminal.

### Step 3: Verify Account Type (Critical!)

User MUST log in with:
- ✅ **Personal Claude Pro/Plus account** (individual subscription)
- ❌ NOT organization/company account (will show "This organization has been disabled")

**Verification command:**
```bash
# Open claude.ai in browser and confirm subscription status
# Or check after login:
claude whoami
```

### Step 4: Verify Login Success

```bash
claude whoami
claude --version
```

Expected output: User info + version (e.g., 2.1.105)

## Common Issues & Fixes

| Issue | Cause | Solution |
|-------|-------|----------|
| "Organization has been disabled" | Logged into org account, not personal | Logout, go to claude.ai, verify personal subscription, re-login |
| Browser doesn't open | Auto-open failed | Manually visit the URL shown in terminal |
| Auth callback hangs | OAuth redirect didn't complete | Check browser URL, ensure redirect to `platform.claude.com` completes |
| Command not found | Installation failed | Check npm global path: `npm config get prefix` |
| 400 API Error after login | Old auth cache conflicting | Clear `~/.claude-code` and `~/.config/claude-code`, retry `claude login` |

## Verification Checklist

- [ ] `claude --version` shows version (e.g., 2.1.105)
- [ ] `claude whoami` returns user info (not API error)
- [ ] Can run `claude` interactively without auth errors
- [ ] User confirms they're using personal subscription account (not org)

## Notes

- Claude Code CLI uses the user's Claude Pro/Plus subscription quota
- No separate API key needed - browser OAuth handles authentication
- Auth tokens stored in system keychain (macOS) or credential manager
- If user had Claude Desktop (DMG) before, auth may conflict - clear caches first
- Organization accounts may be disabled - always verify personal account usage
- npm install is faster than Homebrew (no mirror queue)
