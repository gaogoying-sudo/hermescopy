#!/bin/bash
set -e

# ═══════════════════════════════════════════════════════════
# hermescopy-backup.sh - 一键备份 Hermes 完整灵魂到 GitHub
# 备份范围：配置 + Skills + Cronjob + 自启动 + 项目规则 + 环境清单
# ═══════════════════════════════════════════════════════════

HERMES_HOME="$HOME/.hermes"
HERMESCLONE_DIR="$HOME/Projects/hermescopy"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "📦 hermescopy 一键备份"
echo "======================"
echo "时间：$TIMESTAMP"
echo ""

# ── 检查目录 ──
if [ ! -d "$HERMES_HOME" ]; then
    echo "❌ Hermes 目录不存在：$HERMES_HOME"
    exit 1
fi

if [ ! -d "$HERMESCLONE_DIR" ]; then
    echo "❌ hermescopy 仓库不存在：$HERMESCLONE_DIR"
    exit 1
fi

# ── 1. 备份 Hermes 核心配置 ──
echo "📋 [1/8] 备份 Hermes 核心配置..."
mkdir -p "$HERMESCLONE_DIR/hermes-config"

# 主配置（脱敏）
if [ -f "$HERMES_HOME/config.yaml" ]; then
    echo "  - config.yaml（脱敏）"
    sed -E 's/(api_key|secret|token|KEY).*/\1: "<YOUR_KEY_HERE>"/' \
        "$HERMES_HOME/config.yaml" > "$HERMESCLONE_DIR/hermes-config/config.yaml"
fi

# Memory
if [ -f "$HERMES_HOME/memory.md" ]; then
    echo "  - memory.md"
    cp "$HERMES_HOME/memory.md" "$HERMESCLONE_DIR/hermes-config/memory.md"
fi

# SOUL.md（人格定义）
if [ -f "$HERMES_HOME/SOUL.md" ]; then
    echo "  - SOUL.md"
    cp "$HERMES_HOME/SOUL.md" "$HERMESCLONE_DIR/hermes-config/SOUL.md"
fi

# ── 2. 备份 Skills ──
echo "📋 [2/8] 备份 Skills..."
mkdir -p "$HERMESCLONE_DIR/hermes-config/skills"
if [ -d "$HERMES_HOME/skills" ]; then
    # 备份所有自定义 Skills
    find "$HERMES_HOME/skills" -name "SKILL.md" -type f | while read skill_file; do
        skill_dir=$(dirname "$skill_file")
        skill_rel=$(realpath "$skill_dir" --relative-to="$HERMES_HOME/skills" 2>/dev/null || basename "$skill_dir")
        target_dir="$HERMESCLONE_DIR/hermes-config/skills/$skill_rel"
        mkdir -p "$target_dir"
        cp "$skill_file" "$target_dir/SKILL.md"
        # 复制关联文件
        find "$skill_dir" -maxdepth 1 -type f ! -name "SKILL.md" -exec cp {} "$target_dir/" \;
    done
    skill_count=$(find "$HERMESCLONE_DIR/hermes-config/skills" -name "SKILL.md" | wc -l | tr -d ' ')
    echo "  ✅ 已备份 $skill_count 个 Skills"
fi

# ── 3. 备份 Profiles ──
echo "📋 [3/8] 备份 Profiles..."
if [ -d "$HERMES_HOME/profiles" ]; then
    cp -r "$HERMES_HOME/profiles" "$HERMESCLONE_DIR/hermes-config/profiles"
    profile_count=$(ls -d "$HERMES_HOME/profiles/"*/ 2>/dev/null | wc -l | tr -d ' ')
    echo "  ✅ 已备份 $profile_count 个 Profiles"
fi

# ── 4. 备份 Cronjob 定义 ──
echo "📋 [4/8] 备份 Cronjob 定义..."
mkdir -p "$HERMESCLONE_DIR/hermes-config/cron"
if [ -d "$HERMES_HOME/cron" ]; then
    # 导出所有 cronjob 定义为 JSON
    cp -r "$HERMES_HOME/cron/"* "$HERMESCLONE_DIR/hermes-config/cron/" 2>/dev/null || true
    echo "  ✅ Cronjob 数据已备份"
fi

# 生成可读的 cronjob 清单
cat > "$HERMESCLONE_DIR/hermes-config/cronjob-manifest.md" << 'HEADER'
# Cronjob 清单

> 所有定时任务定义，恢复后可重建

HEADER

echo "**备份时间**：$(date '+%Y-%m-%d %H:%M:%S')" >> "$HERMESCLONE_DIR/hermes-config/cronjob-manifest.md"
echo "" >> "$HERMESCLONE_DIR/hermes-config/cronjob-manifest.md"
echo '```' >> "$HERMESCLONE_DIR/hermes-config/cronjob-manifest.md"

# 读取 cronjob JSON 文件生成清单
for cron_file in "$HERMESCLONE_DIR/hermes-config/cron/"*.json; do
    if [ -f "$cron_file" ]; then
        job_name=$(python3 -c "import json; d=json.load(open('$cron_file')); print(d.get('name', 'unnamed'))" 2>/dev/null || basename "$cron_file")
        job_schedule=$(python3 -c "import json; d=json.load(open('$cron_file')); print(d.get('schedule', 'unknown'))" 2>/dev/null || echo "unknown")
        job_prompt=$(python3 -c "import json; d=json.load(open('$cron_file')); print(d.get('prompt_preview', '')[:100])" 2>/dev/null || echo "")
        echo "- **$job_name** | $job_schedule | $job_prompt" >> "$HERMESCLONE_DIR/hermes-config/cronjob-manifest.md"
    fi
done
echo '```' >> "$HERMESCLONE_DIR/hermes-config/cronjob-manifest.md"

# ── 5. 备份 Launchd 自启动服务 ──
echo "📋 [5/8] 备份 Launchd 自启动服务..."
mkdir -p "$HERMESCLONE_DIR/autostart/launchagents"
LAUNCHD_DIR="$HOME/Library/LaunchAgents"
if [ -d "$LAUNCHD_DIR" ]; then
    # 只备份 AI/开发相关的 plist（排除 Google 等系统级）
    for plist in "$LAUNCHD_DIR"/ai.*.plist "$LAUNCHD_DIR"/com.hermes.*.plist "$LAUNCHD_DIR"/com.mac.*.plist "$LAUNCHD_DIR"/homebrew.mxcl.*.plist; do
        if [ -f "$plist" ]; then
            cp "$plist" "$HERMESCLONE_DIR/autostart/launchagents/"
            echo "  - $(basename "$plist")"
        fi
    done
    plist_count=$(ls "$HERMESCLONE_DIR/autostart/launchagents/"*.plist 2>/dev/null | wc -l | tr -d ' ')
    echo "  ✅ 已备份 $plist_count 个自启动服务"
fi

# 生成启动服务清单
cat > "$HERMESCLONE_DIR/autostart/SERVICES.md" << EOF
# 自启动服务清单

> 备份时间：$(date '+%Y-%m-%d %H:%M:%S')

## Launchd 服务

EOF

for plist in "$HERMESCLONE_DIR/autostart/launchagents/"*.plist; do
    if [ -f "$plist" ]; then
        label=$(defaults read "$plist" Label 2>/dev/null || echo "unknown")
        program=$(defaults read "$plist" Program 2>/dev/null || echo "unknown")
        echo "- \`$label\` → $program" >> "$HERMESCLONE_DIR/autostart/SERVICES.md"
    fi
done

echo "" >> "$HERMESCLONE_DIR/autostart/SERVICES.md"
echo "## 恢复方法" >> "$HERMESCLONE_DIR/autostart/SERVICES.md"
echo '```bash' >> "$HERMESCLONE_DIR/autostart/SERVICES.md"
echo 'cp ~/Projects/hermescopy/autostart/launchagents/*.plist ~/Library/LaunchAgents/' >> "$HERMESCLONE_DIR/autostart/SERVICES.md"
echo 'for f in ~/Library/LaunchAgents/ai.*.plist ~/Library/LaunchAgents/com.hermes.*.plist; do' >> "$HERMESCLONE_DIR/autostart/SERVICES.md"
echo '  launchctl load "$f" 2>/dev/null' >> "$HERMESCLONE_DIR/autostart/SERVICES.md"
echo 'done' >> "$HERMESCLONE_DIR/autostart/SERVICES.md"
echo '```' >> "$HERMESCLONE_DIR/autostart/SERVICES.md"

# ── 6. 备份启动脚本和项目配置 ──
echo "📋 [6/8] 备份启动脚本和项目配置..."
mkdir -p "$HERMESCLONE_DIR/project-configs"
mkdir -p "$HERMESCLONE_DIR/scripts"

# AGENTS.md
find "$HOME/Projects" -maxdepth 2 -name "AGENTS.md" -type f 2>/dev/null | while read agents_file; do
    project_name=$(basename $(dirname "$agents_file"))
    cp "$agents_file" "$HERMESCLONE_DIR/project-configs/AGENTS-${project_name}.md"
    echo "  - $project_name/AGENTS.md"
done

# 启动脚本
for script in "$HOME/Projects/hermes-dashboard/start-dashboard.sh" \
              "$HOME/Projects/clm-tools-kw/docker-compose.yml" \
              "$HOME/Projects/OpenViking/docker-compose.yml"; do
    if [ -f "$script" ]; then
        cp "$script" "$HERMESCLONE_DIR/scripts/"
        echo "  - $(basename "$script")"
    fi
done

# ── 7. 备份 zshrc 自定义部分 ──
echo "📋 [7/8] 备份 shell 配置..."
mkdir -p "$HERMESCLONE_DIR/shell-config"

# 提取自定义部分（排除系统默认的）
cat > "$HERMESCLONE_DIR/shell-config/.zshrc.custom" << 'EOF'
# ═══════════════════════════════════════════════════════════
# zshrc 自定义配置 - hermescopy
# 恢复时追加到 ~/.zshrc
# ═══════════════════════════════════════════════════════════

# Homebrew
export PATH="/opt/homebrew/bin:$PATH"
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
export HOMEBREW_API_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"

# 开发工具路径
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.opencode/bin:$PATH"

# Java
export JAVA_HOME="/opt/homebrew/opt/openjdk"
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

# API 密钥（恢复后需手动填入）
# export DASHSCOPE_API_KEY="your_key_here"
# export OPENROUTER_API_KEY="your_key_here"
# export OPENROUTER_KEY="your_key_here"
EOF
echo "  ✅ .zshrc.custom 已备份"

# ── 8. 生成环境清单 ──
echo "📋 [8/8] 生成环境清单..."
cat > "$HERMESCLONE_DIR/environment-manifest.md" << EOF
# 环境清单 - Environment Manifest

> 自动生成，记录所有依赖和版本，确保可重现

## 系统信息
- **备份时间**：$(date '+%Y-%m-%d %H:%M:%S')
- **操作系统**：$(sw_vers -productName 2>/dev/null || echo 'Linux') $(sw_vers -productVersion 2>/dev/null || echo '')
- **架构**：$(uname -m)
- **Shell**：$SHELL

## Node.js / npm
\`\`\`
node: $(node --version 2>/dev/null || echo '未安装')
npm: $(npm --version 2>/dev/null || echo '未安装')
全局包:
$(npm ls -g --depth=0 2>/dev/null | grep -v "up to date" | head -20)
\`\`\`

## Python
\`\`\`
python3: $(python3 --version 2>/dev/null || echo '未安装')
关键包:
$(pip3 list 2>/dev/null | grep -iE "openpyxl|pandas|graphify|mempalace|hermes")
\`\`\`

## CLI 工具
\`\`\`
$(for cmd in hermes codex claude git gh llm node npm python3 brew; do
    if command -v $cmd &>/dev/null; then
        version=$($cmd --version 2>&1 | head -1)
        echo "$cmd: $version"
    else
        echo "$cmd: 未安装"
    fi
done)
\`\`\`

## Homebrew 包
\`\`\`
$(brew list 2>/dev/null | head -30)
\`\`\`

## 项目目录
\`\`\`
$(ls -d ~/Projects/*/ 2>/dev/null | while read dir; do
    name=$(basename "$dir")
    if [ -d "$dir/.git" ]; then
        branch=$(cd "$dir" && git branch --show-current 2>/dev/null || echo "no-branch")
        echo "📁 $name ($branch)"
    else
        echo "📁 $name"
    fi
done)
\`\`\`

## Cronjob 定时任务
\`\`\`
$(for cron_file in "$HERMESCLONE_DIR/hermes-config/cron/"*.json; do
    if [ -f "$cron_file" ]; then
        name=$(python3 -c "import json; d=json.load(open('$cron_file')); print(d.get('name','?'))" 2>/dev/null)
        schedule=$(python3 -c "import json; d=json.load(open('$cron_file')); print(d.get('schedule','?'))" 2>/dev/null)
        echo "- $name | $schedule"
    fi
done)
\`\`\`

## 自启动服务 (Launchd)
\`\`\`
$(for plist in "$HERMESCLONE_DIR/autostart/launchagents/"*.plist; do
    if [ -f "$plist" ]; then
        label=$(defaults read "$plist" Label 2>/dev/null || basename "$plist")
        echo "- $label"
    fi
done)
\`\`\`
EOF
echo "  ✅ environment-manifest.md 已生成"

# ── 提交到 Git ──
echo ""
echo "📤 提交到 GitHub..."
cd "$HERMESCLONE_DIR"
git add -A
git status --short

echo ""
read -p "确认提交？(y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git commit -m "backup: $TIMESTAMP - 完整灵魂备份"
    git push origin main 2>/dev/null || git push origin master 2>/dev/null || echo "⚠️ 推送失败，请手动 push 或确认 GitHub 仓库已创建"
    echo ""
    echo "✅ 备份完成！"
    echo "   仓库：https://github.com/gaogoying-sudo/hermescopy"
else
    echo "⏸️ 已取消提交（文件已准备好，可手动 git commit）"
fi
