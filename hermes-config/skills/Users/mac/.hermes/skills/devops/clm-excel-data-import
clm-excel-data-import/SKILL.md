---
name: clm-excel-data-import
category: devops
description: Workflow for parsing and importing complex "口味工程师调度看板" Excel data into CLM MySQL, including specific cleaning rules and validation steps.
---

# CLM Excel Data Import & Cleaning

## Overview
Import and clean data from the **global/daily flavor engineer schedule Excel** files.
**Crucial Rule:** These Excel files are the **single source of truth**. Ignore previous MD documentation if it conflicts with Excel data.

## Source Files
Located in `data-sync/inputs/`:
1. `口味工程师调度看板.xlsx` (Primary, large file ~2MB)
2. `全球口味工程师调度看板.xlsx`

## Data Structure Mapping (Sheet 3: 口味日报)
*   **Column 0 (A):** Title (Contains Date prefix, e.g., "2025-12-30...")
*   **Column 3 (D):** Engineer Name (e.g., "曹发", "周华玉")
*   **Column 8 (I):** Dish/SKU Info (Comma-separated, often mixed with status updates)
*   **Column 9 (J):** On-site Issues/Feedback
*   **Column 13 (N):** Date (Excel serial number or YYYY-MM-DD)

## 🧹 Mandatory Cleaning Rules
The "Dish/SKU" column contains **mixed content**. You MUST filter out status updates.

### 1. Blacklist Keywords (Delete if dish_name contains these)
Delete any record where `dish_name` matches:
*   **Status/Versioning:** `%定版%`, `%已定%`, `%未录%`, `%无新%`, `%暂无%`
*   **Process/Actions:** `%协助%`, `%支持%`, `%导入%`, `%培训%`, `%测试%`, `%结束%`, `%POC%`
*   **General Updates:** `%正常%`, `%问题%`, `%稳定%`, `%出餐%`, `%今日%`, `%所有菜品%`, `%出差%`, `%日报%`
*   **Exact Matches:** `已定`, `定版`, `未录菜`, `烹饪出品`, `正常`, `无`, `-`, numbers only (`^[0-9]+$`)

### 2. Length Heuristic
*   If `len(dish_name) > 40`, it is likely a full sentence status update, not a dish name. **Delete it.**

## Import Procedure

### Step 1: Setup Environment
1.  Ensure `openpyxl` or `xml` parsing is available (pandas might fail inside containers).
2.  Target DB: MySQL 8.0 (Container `clm-mysql`).

### Step 2: Parse & Load (Python Script Example)
Write a script inside the container to avoid shell encoding issues:
```python
import os
import pymysql
# Use zipfile to read Excel without heavy libs if needed
from xml.etree import ElementTree as ET

# Connect to DB
conn = pymysql.connect(host='mysql', user='clm', password='clm_pass_2026', database='clm_review')
cursor = conn.cursor()

# Disable FK checks for fast deletes
cursor.execute("SET FOREIGN_KEY_CHECKS = 0")

# 1. Parse XML (Sheet 3 -> xl/worksheets/sheet3.xml)
# ... logic to extract rows ...

# 2. Filter & Insert
clean_dishes = []
for dish in raw_dishes:
    if any(kw in dish for kw in BAD_KEYWORDS): continue
    if len(dish) > 40: continue
    clean_dishes.append(dish)

# 3. Insert into sync_tasks
# 4. Generate/Update daily_sessions based on (engineer, date)
```

### Step 3: Validation
After import, run:
```sql
-- Check for remaining junk
SELECT dish_name, COUNT(*) FROM sync_tasks 
WHERE dish_name LIKE '%定版%' OR dish_name LIKE '%正常%' 
GROUP BY dish_name;

-- Check top real dishes
SELECT dish_name, COUNT(*) as count FROM sync_tasks 
GROUP BY dish_name ORDER BY count DESC LIMIT 10;
```
*   **Expected Top Results:** "辣椒炒肉", "宫保鸡丁", "水煮肉片" (Real dish names).
*   **Failure Indicators:** "已定", "正常", "协助" appearing in top results.

## Pitfalls
1.  **MySQL FK Constraints:** `session_tasks` links to `sync_tasks`. If you clean/delete tasks, you might hit FK errors. Use `SET FOREIGN_KEY_CHECKS = 0` before bulk cleaning.
2.  **Shell Encoding:** Do not paste complex Python one-liners with Chinese characters into the terminal. **Always write to a .py file first** (`docker cp`), then execute.
3.  **Date Parsing:** Excel stores dates as floats (e.g., 46022.5). Convert using `datetime(1899, 12, 30) + timedelta(days=days)`.