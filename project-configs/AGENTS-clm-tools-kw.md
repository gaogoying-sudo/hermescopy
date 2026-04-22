# AGENTS.md

## MemPalace

This project uses MemPalace through MCP.

Rules:
1. Always prefer the MCP server `mempalace` for project memory lookup.
2. Do not run shell commands for MemPalace unless explicitly asked.
3. Always use the MemPalace data under wing `clm_review_tool`.
4. Before making non-trivial code changes, search MemPalace first for related project context.
5. Summarize MemPalace findings before editing code.

## graphify

This project has a graphify knowledge graph at graphify-out/.

Rules:
- Before answering architecture or codebase questions, read graphify-out/GRAPH_REPORT.md for god nodes and community structure
- If graphify-out/wiki/index.md exists, navigate it instead of reading raw files
- After modifying code files in this session, run `python3 -c "from graphify.watch import _rebuild_code; from pathlib import Path; _rebuild_code(Path('.'))"` to keep the graph current

## Obsidian

Project notes are maintained in Obsidian vault at `~/Documents/CLM-Obsidian/`.

Rules:
1. Create/update notes when user asks for documentation or thinking notes
2. Use [[wikilink]] syntax for cross-referencing notes
3. Add #clm tag to all CLM-related notes
4. Do not modify notes without explicit user request

## Karpathy Coding Guidelines

Behavioral rules to reduce common LLM coding mistakes (derived from Andrej Karpathy's observations):

1. **Think Before Coding**: State assumptions explicitly. Surface tradeoffs. Push back if a simpler approach exists. Stop and ask if unclear.
2. **Simplicity First**: Minimum code that solves the problem. No speculative features, no bloated abstractions. If 200 lines could be 50, rewrite it.
3. **Surgical Changes**: Touch only what you must. Don't "improve" adjacent code or refactor things that aren't broken. Match existing style. Clean up only your own mess.
4. **Goal-Driven Execution**: Transform tasks into verifiable goals. "Fix bug" → "Write test that reproduces it, then make it pass". State plan with verification steps.

**Tradeoff**: Bias toward caution over speed. Apply judgment for trivial tasks.

## Governance

Project governance follows docs/GOVERNANCE.md with 5-layer architecture:
- Layer 0: Memory (auto-injected)
- Layer 1: MemPalace (semantic search)
- Layer 2: Obsidian (personal knowledge base)
- Layer 3: docs/ (engineering docs, version controlled)
- Layer 4: graphify (code graph, auto-rebuilt)

Always update docs/progress.md and docs/TASK_BOARD.md at session end.
