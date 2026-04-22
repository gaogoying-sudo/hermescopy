---
name: llm-cli-multi-model-setup
description: Install and configure llm CLI with OpenRouter for multi-model access (Qwen, GPT, Claude, etc.) — alternative when Claude Code CLI account is disabled or for multi-provider access
version: 1.0.0
created: 2026-04-14
---

# LLM CLI Multi-Model Setup

## When to Use

- User's Anthropic/Claude account is disabled but they want CLI access to LLMs
- User wants to access multiple model providers (Qwen/千问，GPT, Claude) from one CLI
- User has OpenRouter subscription and needs terminal-based model access
- Claude Code CLI authentication fails with "organization disabled" error

## Installation Steps

### 1. Install llm CLI

```bash
pipx install llm
```

### 2. Install OpenRouter Plugin

```bash
llm install llm-openrouter
```

### 3. Configure API Key

**Option A: Environment Variable (Recommended ✅)**

This is the most reliable method for llm-openrouter plugin:

```bash
# Set for current session
export OPENROUTER_KEY="sk-or-v1-YOUR_KEY_HERE"

# Make permanent (add to ~/.zshrc)
echo 'export OPENROUTER_KEY="sk-or-v1-YOUR_KEY_HERE"' >> ~/.zshrc
source ~/.zshrc
```

**Option B: Interactive prompt**
```bash
llm keys set openrouter
# Enter key when prompted
```

**⚠️ Important:** The llm-openrouter plugin reads the API key via `llm.get_key()` which checks:
1. Environment variable `OPENROUTER_KEY` (most reliable)
2. llm's internal key storage (may not work consistently)

If you get "401 Unauthorized" errors, use Option A (environment variable).

### 4. Verify Installation

```bash
# List available models
llm models

# Filter for specific providers
llm models | grep -i qwen    # Qwen/千问 models
llm models | grep -i gpt     # GPT models
llm models | grep -i claude  # Claude models
```

## Usage Examples

### Single Query
```bash
# Qwen Plus
llm -m openrouter/qwen-plus "你好，介绍一下你自己"

# GPT-4o
llm -m 4o "帮我写个 Python 脚本"

# Claude Sonnet (via OpenRouter)
llm -m openrouter/claude-sonnet-4 "写一首诗"
```

### Interactive Mode
```bash
llm -m openrouter/qwen-plus
# Starts interactive chat session
```

### With System Prompt
```bash
llm -m openrouter/qwen-plus --system "你是一个专业的程序员" "帮我 review 这段代码"
```

## Available Models (via OpenRouter)

| Provider | Model Alias | Full Model ID |
|----------|-------------|---------------|
| Qwen/千问 | `openrouter/qwen-plus` | qwen/qwen-plus |
| Qwen/千问 | `openrouter/qwen-max` | qwen/qwen-max |
| GPT | `4o` | openai/gpt-4o |
| GPT | `gpt-4.5` | openai/gpt-4.5-preview |
| Claude | `openrouter/claude-sonnet-4` | anthropic/claude-sonnet-4 |

Run `llm models` for full list.

## Troubleshooting

### "API Error: 400 organization disabled"
- This means the Anthropic account is disabled
- Claude Code CLI only works with Anthropic accounts
- **Solution:** Use llm + OpenRouter instead (this skill)

### "Key not found" error
```bash
# Verify key file exists
cat ~/.llm/keys.json

# Re-set the key
llm keys set openrouter
```

### Model not found
```bash
# Check exact model name (model IDs include provider prefix)
llm models | grep -i <provider>

# Use full model ID - format is: openrouter/<provider>/<model>
llm -m openrouter/qwen/qwen-plus "prompt"    # ✅ Correct
llm -m openrouter/qwen-plus "prompt"         # ❌ May not work

# List all OpenRouter models
llm openrouter models
```

### "401 Unauthorized" from OpenRouter API

```bash
# Verify API key is set
echo $OPENROUTER_KEY

# Test key status
llm openrouter key

# If key not found, set environment variable
export OPENROUTER_KEY="sk-or-v1-YOUR_KEY"

# Debug: check how llm reads the key
# The plugin uses llm.get_key("", "openrouter", "OPENROUTER_KEY")
# which prioritizes environment variable over stored keys
```

## Claude Code CLI Installation (Reference)

If user still wants Claude Code CLI installed (for reference or if account gets reinstated):

```bash
# Via npm (faster)
npm install -g @anthropic-ai/claude-code

# Via Homebrew (slower, may queue)
brew install claude-code

# Login (requires browser)
claude auth login

# Check status
claude auth status

# Logout (to switch accounts)
claude auth logout
```

**Note:** Claude Code CLI ONLY works with Anthropic accounts. Cannot use with other model providers.

## Real Session Example (2026-04-14)

Complete working setup from a real session:

```bash
# 1. Install
pipx install llm
llm install llm-openrouter

# 2. Configure API key (environment variable method)
export OPENROUTER_KEY="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"
echo 'export OPENROUTER_KEY="sk-or-v1-YOUR_KEY"' >> ~/.zshrc

# 3. Verify
llm openrouter key    # Should show key info, not 401 error

# 4. List models
llm openrouter models | grep qwen

# 5. Test Qwen
llm -m openrouter/qwen/qwen-plus "你好，测试一下"

# 6. Test GPT-4o
llm -m gpt-4o "Hello, test"
```

## Quick Reference: Model Names

| Use This | Also Works | Description |
|----------|------------|-------------|
| `openrouter/qwen/qwen-plus` | `qwen/qwen-plus` | Qwen Plus |
| `openrouter/qwen/qwen-max` | - | Qwen Max |
| `openrouter/qwen/qwen3-coder-plus` | - | Qwen Coder |
| `gpt-4o` | `openai/gpt-4o` | GPT-4o |
| `4o` | - | GPT-4o (alias) |
| `openrouter/anthropic/claude-opus-4.6-fast` | - | Claude Opus |

---

| Feature | Claude Code CLI | llm + OpenRouter |
|---------|-----------------|------------------|
| Model Access | Claude only | 100+ models |
| Auth Method | Browser OAuth | API Key |
| Account Required | Anthropic subscription | OpenRouter credit |
| Multi-Provider | ❌ No | ✅ Yes |
| Works if Anthropic disabled | ❌ No | ✅ Yes |

## Memory/Notes to Save

- User's Anthropic account (gao.goying@gmail.com) was disabled — use OpenRouter instead
- llm CLI installed via pipx at 2026-04-14
- OpenRouter plugin installed and ready for key configuration
- User has Claude Pro subscription but account disabled (possibly from cracked DMG client)
