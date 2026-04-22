---
name: clm-admin-dashboard-building
category: devops
description: Build a desktop admin dashboard for CLM-REVIEW-TOOL — TailwindCSS componentization, multi-page layout, API integration, and mock data generation for 36 engineers
---

# CLM Admin Dashboard Building

## When to Use
- Building or refactoring CLM-REVIEW-TOOL admin pages
- Similar projects needing a desktop admin dashboard with TailwindCSS + React
- Need to generate realistic mock data for demo/testing

## Architecture

### 5-Page Structure
```
/login          → Demo auth (accept any credentials)
/dashboard      → Stats cards + engineer status table
/search         → Multi-condition search with cache layer
/qa-records     → Three-layer Q&A data (raw/transcribed/structured)
/insights       → Experience candidate review workflow
/settings       → Engineers roster, question templates, datasource config
```

### Component Layout
```
App.jsx (HashRouter + ProtectedRoute + AppLayout)
├── components/Sidebar.jsx    # Collapsible nav, 5 items
├── pages/LoginPage.jsx
├── pages/DashboardPage.jsx   # Stats + engineer table
├── pages/SearchPage.jsx      # Filters + paginated results
├── pages/QARecordsPage.jsx   # Three-layer expand/collapse + export
├── pages/InsightsPage.jsx    # Status tabs + review actions
└── pages/SettingsPage.jsx    # Tabs: engineers/questions/datasource
```

## Key Patterns

### 1. Sidebar with Hash Routing + Role Filtering
```jsx
const navItems = [
  { path: '/dashboard', icon: '📊', label: '数据看板' },
  { path: '/settings', icon: '⚙️', label: '系统管理', roles: ['superadmin'] }, // Restricted
]

// Filter by role from localStorage
const visibleItems = navItems.filter(item => {
  if (item.roles) return item.roles.includes(localStorage.getItem('clm_role') || 'admin')
  return true
})

// Listen for role changes on hashchange
useEffect(() => {
  const h = () => setUserRole(localStorage.getItem('clm_role') || 'admin')
  window.addEventListener('hashchange', h)
  return () => window.removeEventListener('hashchange', h)
}, [])
```

**Without role filtering, non-superadmins see "系统管理" menu but get empty pages when they click it.**

### 2. Protected Route Pattern
```jsx
function ProtectedRoute({ children }) {
  const token = localStorage.getItem('clm_auth_token')
  if (!token) return <Navigate to="/login" replace />
  return children
}
```

### 3. API Client with Centralized Endpoints
```js
// api.js — single source of truth for all API calls
export const api = {
  getDashboard: (date) => request(`/admin/dashboard?target_date=${date}`),
  getEngineers: (date) => request(`/admin/engineers?target_date=${date}`),
  searchData: (params) => {
    const qs = new URLSearchParams(params).toString()
    return request(`/admin/search?${qs}`)
  },
  // ...
}
```

### 4. Three-Layer Data Display (QA Records)
```jsx
// Expandable rows with three data layers
<div className="bg-gray-50 rounded-lg p-3">
  <div className="text-xs font-medium text-gray-500 mb-1">原始输入</div>
  <pre>{raw_input ? JSON.stringify(raw_input, null, 2) : '无'}</pre>
</div>
```

### 5. Export Functions (CSV/JSON)
```js
// CSV export with UTF-8 BOM for Chinese
const csv = rows.map(r => r.map(c => `"${String(c).replace(/"/g, '""')}"`).join(',')).join('\n')
const blob = new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8' })
```

## Mock Data Generation (36 Engineers × 30 Days)

### Files
- `backend/app/mock_data_generator.py` — Generates realistic cooking tasks
- `backend/app/seed_30day_data.py` — Populates MySQL with generated data

### Recipe Library (16 dishes)
辣椒炒肉/青椒肉丝/麻婆豆腐/红烧肉/宫保鸡丁/鱼香肉丝/水煮鱼/回锅肉/糖醋排骨/干锅花菜/酸菜鱼/剁椒鱼头/小炒黄牛肉/煎鸡蛋 + variants

### Data Distribution
- 36 engineers, each works 15-25 days in past 30
- 1-4 tasks per working day
- 70% session creation rate
- 86.5% submission rate among created sessions
- 25% abnormal task rate

### Seed Command
```bash
docker exec clm-backend python3 /app/app/seed_30day_data.py
```

## Search API with Cache

### Backend Pattern
```python
_cache = {}
_CACHE_TTL = 300  # 5 minutes

def _cache_key(params):
    return hashlib.md5(json.dumps(params, sort_keys=True).encode()).hexdigest()

# Check cache before query (skip for today's data)
if not is_today_search:
    cached = _cache.get(_cache_key(params))
    if cached: return {"from_cache": True, **cached}
```

### API Endpoints
- `GET /api/admin/search` — Multi-condition search (date/engineer/dish/status/abnormal)
- `GET /api/admin/qa-records` — Q&A records with three-layer data + keyword search

## Common Pitfalls

1. **ADMIN_TOKEN_STORAGE_KEY corruption**: If api.js shows `***` instead of actual key, admin API calls fail silently. Fix by rewriting api.js with correct key.

2. **Questions API duplicate definition**: After adding getQuestions/createQuestion/updateQuestion/deleteQuestion, check for duplicates in api.js (the old inline-style code had these duplicated).

3. **Search returns empty for today**: Today's data is intentionally not cached. Use date range that excludes today for cache hits.

4. **QA Records empty until submissions exist**: The qa-records endpoint requires actual Answer records. Until engineers submit answers, this page will show empty.

5. **Hash router vs browser router**: Use HashRouter (not BrowserRouter) for static file serving with nginx. Otherwise page refreshes 404.

## TailwindCSS Setup
```bash
npm install tailwindcss @tailwindcss/vite react-router-dom
# vite.config.js: import tailwindcss from '@tailwindcss/vite'
# Add tailwindcss() to plugins array
# Create src/index.css: @import "tailwindcss";
```

## Verification Checklist
- [ ] All 5 pages render without errors
- [ ] Dashboard shows stats cards with real numbers
- [ ] Search returns results with filter combinations
- [ ] QA Records shows three-layer data when answers exist
- [ ] Insights shows candidate review workflow
- [ ] Settings shows 36 engineers + 7 question templates
- [ ] CSV/JSON export downloads correctly
- [ ] Sidebar collapse/expand works
- [ ] Login/logout cycle works