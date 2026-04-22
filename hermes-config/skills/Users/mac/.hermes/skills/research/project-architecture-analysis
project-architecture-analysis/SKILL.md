---
name: project-architecture-analysis
description: Systematic analysis of external AI/developer tools projects — evaluate features, installation, architecture compatibility, and integration potential with existing systems.
trigger: When user asks to analyze/evaluate/research an external project, tool, or framework for potential integration.
---

# Project Architecture Analysis Workflow

## Purpose
Evaluate external projects (especially AI tools, knowledge management systems, developer tools) for:
1. Core functionality and value proposition
2. Installation/deployment requirements
3. Compatibility with existing system architecture
4. Integration potential and conflict points
5. Recommendation for adoption

## Step-by-Step Process

### Phase 1: Information Gathering (15-30 min)

1. **Search for project overview**
   ```python
   web_search(query="<project-name> GitHub AI tool overview")
   ```

2. **Extract key documentation**
   ```python
   web_extract(urls=[
       "https://github.com/<org>/<project>",
       "https://docs.<project>.dev/",
       "https://docs.<project>.dev/get-started/setup"
   ])
   ```

3. **Search for architecture/integration details**
   ```python
   web_search(query="<project> architecture RAG integration <related-tech>")
   ```

4. **Extract client/integration docs** (if applicable)
   ```python
   web_extract(urls=[
       "https://docs.<project>.dev/clients/<integration>",
       "https://docs.<project>.dev/features/<key-feature>"
   ])
   ```

### Phase 2: Analysis Framework

Create a structured analysis document with these sections:

#### 1. Project Overview Table
| Metric | Value |
|--------|-------|
| GitHub Stars | |
| License | |
| Latest Release | |
| Primary Languages | |
| Community Size | |

#### 2. Core Features List
- List all major capabilities
- Note unique selling points
- Identify target use cases

#### 3. Technical Architecture
- Backend stack (frameworks, databases)
- Frontend stack (if applicable)
- Deployment options (Docker, Pip, etc.)
- Key configuration options

#### 4. Installation Methods
Document all installation options:
- Docker setup (commands, env vars)
- Pip/npm installation (platform-specific commands)
- Cloud/SaaS option (if available)

#### 5. Compatibility Analysis

**Conflict Assessment:**
| Area | Existing System | External Project | Conflict Level |
|------|-----------------|------------------|----------------|
| Knowledge Management | | | 🟢/🟡/🔴 |
| AI/Agent Framework | | | 🟢/🟡/🔴 |
| Search/Indexing | | | 🟢/🟡/🔴 |
| Client Integrations | | | 🟢/🟡/🔴 |
| Port/Resource Usage | | | 🟢/🟡/🔴 |

**Complementary Opportunities:**
- Identify areas where external project enhances existing system
- Note integration points (APIs, plugins, shared data formats)

#### 6. Installation Recommendations
- Preferred installation method (isolated vs integrated)
- Port assignments (check multi-team-port-management skill)
- Configuration for existing infrastructure (e.g., OpenRouter for LLMs)

#### 7. Decision Framework

**✅ Recommend adoption when:**
- Fills genuine capability gap
- No significant architecture conflicts
- Active community and maintenance
- License compatible with use case

**❌ Discourage adoption when:**
- Significant overlap with existing tools
- High integration complexity
- License restrictions (e.g., AGPL for commercial use)
- Declining community/maintenance

### Phase 3: Documentation

1. **Create analysis report**
   ```python
   write_file(
       path="docs/research/<project>-analysis.md",
       content=<full analysis document>
   )
   ```

2. **Update progress log**
   ```python
   patch(
       path="docs/progress.md",
       old_string=<last entry>,
       new_string=<last entry + new analysis entry>
   )
   ```

3. **Offer to create skill** (if analysis revealed reusable patterns)

### Phase 4: Next Steps Recommendation

Provide concrete next steps:
```
1. [ ] Local isolated testing (estimated time)
2. [ ] Verify integration with <specific component>
3. [ ] Test <key feature> compatibility
4. [ ] Evaluate production readiness
5. [ ] Decision: adopt/reject/review later
```

## Key Considerations

### License Awareness
- AGPL-3.0: Requires open-sourcing derivative works (network distribution)
- GPL-3.0: Similar to AGPL but less strict on network use
- MIT/Apache/BSD: Permissive, commercial-friendly
- Note license implications in analysis

### Architecture Conflicts to Watch
1. **Port collisions** — check existing port assignments
2. **Database conflicts** — multiple services using same DB
3. **Authentication systems** — competing auth mechanisms
4. **Data format incompatibilities** — different storage schemas
5. **Client plugin conflicts** — e.g., multiple Obsidian plugins

### Integration Patterns
1. **Side-by-side** — Run independently, no data sharing
2. **API integration** — One system calls the other's API
3. **Shared data layer** — Both systems read/write same data store
4. **Plugin/extension** — One system extends the other

## Output Template

```markdown
# <Project Name> Analysis Report

**Analysis Date:** YYYY-MM-DD  
**Analysis By:** <role>  
**Project Source:** <URL>

## 📊 Project Overview
<overview table>

## 🚀 Core Features
<feature list>

## 🏗 Technical Architecture
<architecture details>

## 🛠 Installation Methods
<installation commands>

## 🔍 Compatibility Analysis
<conflict/complement assessment>

## 📋 Installation Recommendations
<recommended approach>

## 🎯 Decision Recommendations
<adoption criteria>

## 📚 References
<link list>
```

## Pitfalls

1. **Don't assume compatibility** — verify API formats, auth mechanisms, data schemas
2. **Check license early** — AGPL may be non-starter for commercial projects
3. **Consider operational overhead** — new service = new monitoring, backups, updates
4. **Evaluate community health** — check GitHub activity, issue response time, release frequency
5. **Test in isolation first** — always start with Docker/separate environment before integration

## Related Skills

- `multi-team-port-management` — Coordinate port assignments across projects
- `clm-project-governance` — Five-layer governance architecture
- `graphify-install` — Knowledge graph tool integration
- `clm-session-completion-workflow` — End-of-session documentation ritual
