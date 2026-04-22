---
name: hermes-full-backup
description: Complete backup and recovery system for Hermes Agent — backs up configuration, skills, profiles, memory, cronjobs, autostart services, project rules, startup scripts, shell config, and environment manifest. Includes backup, restore, and verify scripts with automated scheduling.
version: 1.0.0
license: MIT
---

# Hermes Full Backup (hermescopy)

Complete backup and recovery system for Hermes Agent. Ensures no "soul" is lost — every configuration, skill, habit, and behavior is reproducible on a new machine.

## Problem

Hermes setup is complex and multi-layered. A simple config backup is insufficient because:
- Skills (400+ files) are custom-built over time
- Cronjob definitions define automated workflows
- Launchd plist files control autostart services
- Memory.md contains accumulated project knowledge
- AGENTS.md files contain project-specific behavioral rules
- Shell config contains paths, mirrors, and environment variables
- Startup scripts (dashboard, docker-compose) are customized

**Key insight:** Backing up "config files" is not enough. You need to back up "runtime state" and "behavioral habits" too.

## Architecture

```
hermescopy/ (GitHub repo)
├── hermescopy-backup.sh        # Backup script
├── hermescopy-restore.sh       # Restore script
├── hermescopy-verify.sh        # Verification script
├── README.md                   # Documentation
├── environment-manifest.md     # Auto-generated env清单
├── hermes-config/              # Hermes core config
│   ├── config.yaml             # Main config (desensitized)
│   ├── memory.md               # Memory document
│   ├── SOUL.md                 # Personality definition
│   ├── skills/                 # All custom Skills
│   ├── profiles/               # Role configurations
│   └── cron/                   # Cronjob data + manifest
├── autostart/                  # Launchd services
│   ├── launchagents/           # plist files
│   └── SERVICES.md             # Service清单 + restore method
├── project-configs/            # Project AGENTS.md files
├── scripts/                    # Startup scripts
└── shell-config/
    └── .zshrc.custom           # Shell custom config
```

## Scripts

### 1. hermescopy-backup.sh

Backs up 8 categories:
1. **Hermes core config** — config.yaml (desensitized), memory.md, SOUL.md
2. **Skills** — All custom Skills (find SKILL.md, copy with linked files)
3. **Profiles** — All role configurations
4. **Cronjob definitions** — JSON data + readable manifest
5. **Launchd autostart services** — ai.*.plist, com.hermes.*.plist, homebrew.mxcl.*.plist
6. **Startup scripts & project config** — AGENTS.md, start-dashboard.sh, docker-compose.yml
7. **Shell config** — .zshrc custom section
8. **Environment manifest** — Auto-generated清单 of tools, versions, dependencies

**Desensitization:** API keys are replaced with `<YOUR_KEY_HERE>` before committing to GitHub.

### 2. hermescopy-restore.sh

Restores everything in order:
1. Install Hermes (if missing)
2. Backup existing config (to .backup.TIMESTAMP)
3. Restore core config (config.yaml, memory.md, SOUL.md)
4. Restore Skills
5. Restore Profiles
6. Restore Cronjob data
7. Restore Launchd services (and load them)
8. Restore project configs and startup scripts
9. Create .env template (user fills in keys manually)
10. Install CLI tools (codex, claude, openclaw)
11. Run verification

### 3. hermescopy-verify.sh

Checks 8 categories with pass/warn/fail:
1. Hermes core (CLI, config.yaml, memory.md, SOUL.md, .env)
2. Skills (count + key skills like karpathy-guidelines)
3. Profiles (count)
4. Cronjob (count)
5. CLI tools (hermes, codex, claude, git, node, npm)
6. Autostart services (Launchd status)
7. Project configs (AGENTS.md presence)
8. Python dependencies (openpyxl, pandas)

## Usage

### Backup (manual)
```bash
cd ~/Projects/hermescopy
./hermescopy-backup.sh
```

### Backup (automated)
Set up a cronjob to run weekly:
```
Schedule: 0 9 * * 1 (Monday 9:00 AM)
Prompt: cd ~/Projects/hermescopy && echo "y" | ./hermescopy-backup.sh
```

### Restore (new machine)
```bash
# Method 1: Local repo
git clone git@github.com:gaogoying-sudo/hermescopy.git ~/Projects/hermescopy
cd ~/Projects/hermescopy
./hermescopy-restore.sh

# Method 2: One-liner (remote)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/gaogoying-sudo/hermescopy/main/hermescopy-restore.sh)" \
    git@github.com:gaogoying-sudo/hermescopy.git
```

### Verify
```bash
./hermescopy-verify.sh
```

## What NOT to backup (security)

- API keys (desensitized in backup, manually filled after restore)
- auth.json / session tokens (re-login after restore)
- sessions/ / state.db (runtime data, auto-rebuilt)
- Project source code (each has its own Git repo)

## Pitfalls

1. **Git URL pollution:** On this machine, `git remote set-url/add` injects ` -S -p ''` suffix into URLs. Fix: edit `.git/config` directly instead of using git commands.
2. **Memory limit:** The memory tool has a 2200 char limit. Keep backup references concise.
3. **Cronjob format:** Use cron format (e.g., `0 9 * * 1`), not natural language (e.g., "monday 09:00").
4. **Launchd loading:** After restoring plist files, run `launchctl load` to activate them. Some may fail if already loaded — that's OK.
5. **Shell config:** .zshrc.custom is provided as a template — user must manually append it to their .zshrc.

## Key Design Principles

1. **Backup the "soul," not just the config** — Skills, habits, behaviors, autostart, cronjobs
2. **Desensitize, don't expose** — API keys never go to GitHub
3. **Verify, don't trust** — Always run verify.sh after restore
4. **Automate, don't remember** — Weekly cronjob backup, no manual intervention needed
5. **Reproducible, not just portable** — Environment manifest ensures the same toolchain can be rebuilt
