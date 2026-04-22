---
name: graphify-install
description: Install and configure Graphify knowledge graph tool — handles Python version requirements, uv-managed environments, and platform-specific setup
tags: [graphify, knowledge-graph, python, installation, uv, macos]
created: 2026-04-10
---

# Graphify Installation & Setup

**Graphify** turns any codebase into a queryable knowledge graph. 18k+ stars. Reduces token usage by 71.5x vs reading raw files.

## Prerequisites

- **Python 3.10+** (required — will fail on 3.9)
- macOS, Linux, or Windows

## Installation Steps

### 1. Check Python Version

```bash
python3 --version
```

If < 3.10, find an alternative Python:

```bash
# Check for uv-managed Python
ls ~/.local/bin/python3.1* 2>/dev/null

# Check for Homebrew Python
ls /opt/homebrew/bin/python3.* 2>/dev/null

# Or install via uv
brew install python@3.11
```

### 2. Install graphifyy Package

**For uv-managed Python** (common on macOS):

```bash
/Users/mac/.local/bin/python3.11 -m pip install graphifyy --break-system-packages
```

**For system Python** (if not externally managed):

```bash
python3 -m pip install graphifyy
```

**Note:** PyPI package is `graphifyy` (two y's), but CLI command is `graphify`.

### 3. Verify Installation

```bash
# Find the graphify command location
python3 -c "import graphify; print(graphify.__file__)"

# Test the CLI
graphify --help
```

Common locations:
- uv: `~/.local/share/uv/python/cpython-3.11.x/bin/graphify`
- pipx: `~/.local/bin/graphify`
- system: `/usr/local/bin/graphify`

### 4. Add to PATH (Optional)

```bash
echo 'export PATH="$HOME/.local/share/uv/python/cpython-3.11.14-macos-aarch64-none/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

## Platform Integration

Graphify works through AI assistant skills. Run the install command for your platform:

| Platform | Command |
|----------|---------|
| Claude Code | `graphify claude install` |
| Codex | `graphify codex install` |
| OpenCode | `graphify opencode install` |
| Cursor | `graphify cursor install` |
| OpenClaw | `graphify claw install` |
| Factory Droid | `graphify droid install` |
| Trae | `graphify trae install` |
| Aider | `graphify aider install` |

This writes platform-specific config (e.g., `AGENTS.md`, `CLAUDE.md`, hooks) to enable always-on graph awareness.

## Usage

### Generate a Knowledge Graph

Through your AI assistant (after platform install):

```
/graphify .                      # Current directory
/graphify ./src --mode deep      # Aggressive inference
/graphify ./src --watch          # Auto-sync on file changes
```

### Query the Graph

```bash
# Via CLI (requires existing graph.json)
graphify query "what is the auth flow?"
graphify query "..." --dfs
graphify path "ClassA" "ClassB"
graphify explain "SomeNode"
```

### Outputs

Running graphify generates `graphify-out/`:

```
graphify-out/
├── graph.html       # Interactive visualization
├── GRAPH_REPORT.md  # God nodes, architecture insights
├── graph.json       # Persistent graph data
└── cache/           # SHA256 cache for incremental updates
```

### Keep Graph Fresh

```bash
# Install git hooks for auto-rebuild
graphify hook install

# Or use watch mode
/graphify . --watch
```

## Troubleshooting

### "Requires Python 3.10+"

```bash
# Find Python 3.10+
which python3.10 python3.11 python3.12

# Or use uv to manage Python
curl -LsSf https://astral.sh/uv/install.sh | sh
uv python install 3.11
```

### "externally-managed-environment"

This means Python is managed by uv/pipx. Use one of:

```bash
# Option 1: Use the uv Python directly
/Users/mac/.local/bin/python3.11 -m pip install graphifyy --break-system-packages

# Option 2: Use pipx
pipx install graphifyy

# Option 3: Use uv pip
uv pip install graphifyy --system
```

### "command not found: graphify"

Find where it was installed:

```bash
python3 -c "import os, graphify; print(os.path.dirname(graphify.__file__) + '/../bin/graphify')"
```

Then add that directory to PATH or use the full path.

### Graph Not Building

Graphify builds graphs through AI assistant skills, not directly via CLI. Make sure you:

1. Run `graphify <platform> install` first
2. Use your AI assistant with `/graphify .` command
3. Check that the assistant has permission to read files

## Key Concepts

- **Two-pass extraction:** AST (tree-sitter, no LLM) + LLM subagents for docs
- **Leiden clustering:** Community detection without embeddings
- **Relationship tags:** EXTRACTED (direct), INFERRED (confidence score), AMBIGUOUS
- **Incremental updates:** SHA256 cache only re-processes changed files
- **No vector DB needed:** Pure graph-topology-based clustering
