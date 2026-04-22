---
name: clm-frontend-rapid-enhancement
category: devops
created: 2026-04-13
description: Rapid frontend enhancement workflow for CLM project with immediate cloud deployment
---

# CLM Frontend Rapid Enhancement Workflow

**Context:** CLM-REVIEW-TOOL project frontend enhancements with immediate cloud deployment

## When to Use

- User requests frontend feature fixes/enhancements
- User gives full authorization to proceed autonomously
- Quick turnaround expected (same session deployment)
- Cloud deployment required after code changes

## Workflow Steps

### 1. Understand Requirements (5 min)
- Read existing frontend component code
- Identify backend API changes needed
- Clarify visualization requirements (waterfall, charts, etc.)

### 2. Implement Frontend Changes (30-60 min)

**For Cache/State Retention:**
```jsx
// localStorage caching pattern
const CACHE_KEY = 'clm_search_cache_v1'
const CACHE_TTL = 5 * 60 * 1000 // 5 minutes

const loadFromCache = () => {
  try {
    const cached = localStorage.getItem(CACHE_KEY)
    if (cached) {
      const { filters, results, total, timestamp } = JSON.parse(cached)
      if (Date.now() - timestamp < CACHE_TTL) {
        return { savedFilters: filters, savedResults: results, savedTotal: total }
      }
    }
  } catch (e) { console.error('Load cache error:', e) }
  return null
}

const saveToCache = (filters, results, total) => {
  try {
    localStorage.setItem(CACHE_KEY, JSON.stringify({
      filters, results, total, timestamp: Date.now()
    }))
  } catch (e) { console.error('Save cache error:', e) }
}
```

**For Waterfall/Visualization:**
```jsx
// Power trace waterfall (blue bar chart)
{t.power_trace?.length > 0 && (
  <div className="h-32 bg-white rounded border border-gray-200 p-2 overflow-x-auto">
    <div className="flex items-end gap-1 h-full" style={{minWidth: `${t.power_trace.length * 20}px`}}>
      {t.power_trace.slice(0, 50).map((pt, i) => {
        const height = Math.min(100, (pt.power || 0) / 120)
        return (
          <div key={i} className="flex-1 bg-blue-500 rounded-t" 
               style={{height: `${height}%`}} 
               title={`${pt.time || i}s: ${pt.power}W`}></div>
        )
      })}
    </div>
  </div>
)}
```

### 3. Implement Backend Changes (15-30 min)

**Add Database Fields:**
```python
# models.py
cook_steps = Column(JSON, default=list, comment="烹饪步骤 [{step,time,temp,cmd,desc}]")
```

**Enhance API Response:**
```python
# routers/search.py
"power_trace": t.power_trace or [],
"ingredients_timeline": t.ingredients_timeline or [],
"ingredient_notes": t.ingredient_notes or [],
"cook_steps": t.cook_steps or [],
"cooking_time": t.cooking_time,
"max_power": t.max_power,
```

### 4. Build Frontend (5 min)
```bash
cd frontend
npm run build
```

### 5. Git Commit & Push (5 min)
```bash
cd /Users/mac/Projects/clm-tools-kw
git add -A
git commit -m "fix: <description>"
git push origin main
```

### 6. Create Deployment Documentation (10 min)

**Quick Deploy Guide** (`docs/DEPLOY_QUICK.md`):
- SSH commands for deployment
- Verification steps
- Troubleshooting section

**User Check Guide** (`docs/USER_CHECK_GUIDE.md`):
- Step-by-step verification
- Expected screenshots/interface
- Problem reporting template

**Deploy Report** (`docs/DEPLOY_REPORT_YYYYMMDD.md`):
- What was fixed
- Technical details
- Git commits
- Next steps

### 7. Deploy Scripts (10 min)

**Enhanced Deploy Script** (`scripts/deploy-enhanced.sh`):
```bash
#!/bin/bash
set -e
cd /opt/clm-review-tool
git pull
docker compose restart
sleep 10
curl -s http://localhost:8001/health | grep -q 'ok' || exit 1
echo "✅ Deploy complete"
```

### 8. Update Task Board
```bash
# Update docs/TASK_BOARD.md
# Update docs/progress.md
# Run graphify rebuild
cd /Users/mac/Projects/clm-tools-kw
.venv/bin/python3 -c "from graphify.watch import _rebuild_code; from pathlib import Path; _rebuild_code(Path('.'))"
```

## Pitfalls

1. **localStorage TTL** - Always set expiration (5 min recommended) to avoid stale data
2. **Waterfall scaling** - Normalize values (0-100%) for consistent visualization
3. **Array slicing** - Limit displayed items (50 for charts, 10 for lists) to avoid performance issues
4. **Database migrations** - New JSON fields don't require migration if using SQLAlchemy + JSON default
5. **Build before deploy** - Always run `npm run build` before git commit
6. **SSH key auth** - Cloud server requires SSH key, not password

## Verification Checklist

- [ ] Frontend builds without errors
- [ ] Backend API returns enhanced data
- [ ] localStorage cache works (refresh page, verify data persists)
- [ ] Visualization renders correctly
- [ ] Git commit pushed
- [ ] Deploy scripts created
- [ ] Documentation complete
- [ ] User check guide clear

## Related Skills

- `clm-admin-dashboard-building` - Initial dashboard creation
- `clm-session-completion-workflow` - End-of-session governance
- `clm-project-governance` - Five-layer architecture
