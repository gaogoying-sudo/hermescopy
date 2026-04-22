---
name: evoagentx-install-and-config
description: Install and configure EvoAgentX framework with isolated Python environment and LLM API key configuration
version: 1.0.0
created: 2026-04-16
---

# EvoAgentX Installation and Configuration

## When to Use

- User wants to install EvoAgentX (self-evolving AI agent framework)
- User has existing LLM API keys (DashScope, OpenRouter, etc.) that should be discovered and reused
- User prefers isolated project environments (one venv per project)

## Prerequisites

- Python 3.11 or higher (REQUIRED - EvoAgentX will not work with Python 3.9/3.10)
- Check available Python versions: `ls /usr/local/bin/python* /opt/homebrew/bin/python* ~/.local/bin/python*`

## Installation Steps

### 1. Check Python Version

```bash
# Find Python 3.11+ installation
which python3.11 python3.12
ls ~/.local/bin/python* /opt/homebrew/bin/python* 2>/dev/null
```

### 2. Create Isolated Project Environment

**Option A: Using uv (faster, recommended)**
```bash
# Create project directory
mkdir -p ~/Projects/evoagentx
cd ~/Projects/evoagentx

# Create venv with uv (auto-detects Python 3.11+)
uv venv --python 3.11
source .venv/bin/activate
```

**Option B: Using standard venv**
```bash
# Create project directory
mkdir -p ~/Projects/evoagentx
cd ~/Projects/evoagentx

# Create venv with Python 3.11+
/Users/mac/.local/bin/python3.11 -m venv venv
source venv/bin/activate
pip install --upgrade pip
```

### 3. Install EvoAgentX

**Option A: Full install (recommended)**
```bash
# Install from GitHub (includes all dependencies)
uv pip install evoagentx
# OR
pip install git+https://github.com/EvoAgentX/EvoAgentX.git
```

**Option B: Minimal install (faster, add deps as needed)**
```bash
# Install core package only
uv pip install evoagentx --no-deps

# Add minimal dependencies for testing
uv pip install pyyaml python-dotenv openai httpx dashscope loguru tenacity
```

**Verify installation:**
```bash
python3 -c "import evoagentx; print(evoagentx.__version__)"
```

## API Key Discovery

Search for user's existing LLM API keys before asking them to provide new ones:

```bash
# Search common locations
grep -r "DASHSCOPE\|ALIYUN\|QWEN.*KEY" ~/.zshrc ~/.hermes/.env ~/Projects/*/env/ 2>/dev/null
find ~ -name ".env*" -type f 2>/dev/null | xargs grep -l "sk-" 2>/dev/null | head -10

# Check Hermes history for previously shared keys
cat ~/.hermes/.hermes_history | grep "sk-"

# Check project-specific configs
find ~/Projects -name ".env*" -type f 2>/dev/null
```

### Common Key Locations

| Location | Description |
|----------|-------------|
| `~/.zshrc` | Environment variables (OPENROUTER_KEY, DASHSCOPE_API_KEY) |
| `~/.hermes/.env` | Hermes agent configuration |
| `~/Projects/*/env/.env.*` | Project-specific environment files |
| `~/.llm/keys.json` | LLM CLI keys |

## Configuration

### Option A: Alibaba DashScope (Recommended for Qwen)

```bash
# Create .env file
cat > ~/Projects/evoagentx/.env << EOF
DASHSCOPE_API_KEY=your_dashscope_key
DASHSCOPE_BASE_URL=https://dashscope.aliyuncs.com/compatible-mode/v1
DEFAULT_MODEL=qwen-plus
EOF
```

**DashScope Model IDs:**
- `qwen-plus` - Qwen Plus (balanced)
- `qwen-max` - Qwen Max (best quality)
- `qwen-turbo` - Qwen Turbo (fastest)
- `qwen3.5-235b-a22b-instruct-128k` - Qwen 3.5 (latest)

**DashScope Endpoints:**
- Standard: `https://dashscope.aliyuncs.com/compatible-mode/v1` (recommended)
- Specialized: `https://coding.dashscope.aliyuncs.com/v1` (for specific services only)

### Option B: OpenRouter (Multi-provider)

```bash
# Create .env file
cat > ~/Projects/evoagentx/.env << EOF
OPENROUTER_API_KEY=sk-or-your_key
DEFAULT_MODEL=qwen/qwen-3.5
EOF
```

**OpenRouter Model IDs:**
- `qwen/qwen-3.5` - Qwen 3.5
- `qwen/qwen-plus` - Qwen Plus
- `qwen/qwen-max` - Qwen Max

## API Key Recognition

| Key Prefix | Service | Endpoint |
|------------|---------|----------|
| `sk-sp-` | Alibaba DashScope | `dashscope.aliyuncs.com` |
| `sk-or-` | OpenRouter | `openrouter.ai` |
| `sk-` (other) | OpenAI-compatible | Varies |

**⚠️ Important:** Some DashScope keys (e.g., `sk-sp-*`) are for specialized services and may not work with the standard endpoint. If you get "model not supported" errors:
1. Try the standard endpoint: `https://dashscope.aliyuncs.com/compatible-mode/v1`
2. If that returns "invalid API key", the key is for a specialized service
3. User needs to create a new key at https://dashscope.console.aliyun.com/

## Test Configuration

Create test script:

```python
#!/usr/bin/env python3
import os
from dotenv import load_dotenv

load_dotenv()

from evoagentx.models import OpenAILLMConfig, OpenAILLM

api_key = os.getenv("DASHSCOPE_API_KEY") or os.getenv("OPENROUTER_API_KEY")
if not api_key:
    print("❌ No API key found")
    exit(1)

# DashScope configuration
config = OpenAILLMConfig(
    model="qwen-plus",
    openai_key=api_key,
    base_url="https://dashscope.aliyuncs.com/compatible-mode/v1",  # DashScope
    # base_url="https://openrouter.ai/api/v1",  # OpenRouter
    stream=True,
    output_response=True
)

llm = OpenAILLM(config=config)
response = llm.generate(prompt="用一句话介绍 EvoAgentX")
print(f"✅ Response: {response}")
```

Run test:

```bash
cd ~/Projects/evoagentx
source venv/bin/activate
python3 test_qwen.py
```

## Troubleshooting

### Python Version Error

```
# Error: EvoAgentX requires Python 3.11+
# Solution: Find and use Python 3.11+ explicitly
ls ~/.local/bin/python* /opt/homebrew/bin/python*
/Users/mac/.local/bin/python3.11 -m venv venv
```

### API Key Not Found

```bash
# Search more broadly
grep -r "sk-" ~ 2>/dev/null | grep -v "Binary\|.json\|node_modules" | head -20

# Check if key is in environment
env | grep -i "key\|api"
```

### Module Not Found After Install

```bash
# Verify venv is using correct Python
which python3
python3 --version

# Reinstall if needed
pip uninstall evoagentx
pip install git+https://github.com/EvoAgentX/EvoAgentX.git
```

### API Endpoint Errors

**Error: "model `qwen-plus` is not supported"**
```
# Cause: Using specialized endpoint (e.g., coding.dashscope.aliyuncs.com)
# Solution: Use standard endpoint
DASHSCOPE_BASE_URL=https://dashscope.aliyuncs.com/compatible-mode/v1
```

**Error: "Incorrect API key provided" (401)**
```
# Cause: Key is for specialized service or wrong endpoint
# Solution:
# 1. Try standard endpoint first
# 2. If still fails, key may be for specialized service (通义灵码, etc.)
# 3. User needs to create new key at https://dashscope.console.aliyun.com/
```

**Test script for endpoint troubleshooting:**
```python
import requests

api_key = "your-key"
endpoints = [
    "https://dashscope.aliyuncs.com/compatible-mode/v1",
    "https://coding.dashscope.aliyuncs.com/v1"
]

for endpoint in endpoints:
    response = requests.post(
        f"{endpoint}/chat/completions",
        headers={"Authorization": f"Bearer {api_key}"},
        json={"model": "qwen-plus", "messages": [{"role": "user", "content": "hi"}]}
    )
    print(f"{endpoint}: {response.status_code} - {response.text[:100]}")
```

## User Preferences

- **Isolated environments**: Always create separate venv per project (~/Projects/<project>/venv/)
- **Key discovery**: Search existing configs before asking user for new keys
- **DashScope preferred**: For Qwen models, DashScope is cheaper and more stable than OpenRouter
- **Test before use**: Always run a test query after configuration

## Quick Reference

```bash
# Full install + config workflow (uv - faster)
mkdir -p ~/Projects/evoagentx && cd ~/Projects/evoagentx
uv venv --python 3.11
source .venv/bin/activate
uv pip install evoagentx

# Create .env (fill in actual key)
cat > .env << EOF
DASHSCOPE_API_KEY=<your_key>
DASHSCOPE_BASE_URL=https://dashscope.aliyuncs.com/compatible-mode/v1
EOF

# Test
python3 -c "import evoagentx; print(evoagentx.__version__)"
```

```bash
# Full install + config workflow (pip - standard)
mkdir -p ~/Projects/evoagentx && cd ~/Projects/evoagentx
/Users/mac/.local/bin/python3.11 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install git+https://github.com/EvoAgentX/EvoAgentX.git

# Create .env
cat > .env << EOF
DASHSCOPE_API_KEY=<your_key>
EOF

# Test
python3 -c "import evoagentx; print(evoagentx.__version__)"
```

## Test Script Template

Save as `test_qwen.py`:

```python
#!/usr/bin/env python3
import os
from dotenv import load_dotenv
load_dotenv()

from evoagentx.models import OpenAILLMConfig, OpenAILLM

api_key = os.getenv("DASHSCOPE_API_KEY")
base_url = os.getenv("DASHSCOPE_BASE_URL", "https://dashscope.aliyuncs.com/compatible-mode/v1")

if not api_key:
    print("❌ No API key found")
    exit(1)

config = OpenAILLMConfig(
    model="qwen-plus",
    openai_key=api_key,
    base_url=base_url,
    stream=True,
    output_response=True
)

llm = OpenAILLM(config=config)
print("🚀 Testing connection...")
response = llm.generate(prompt="用一句话介绍 EvoAgentX")
print(f"✅ Response: {response}")
```
