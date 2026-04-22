---
name: fcm-sample-selection-matrix
category: certification
description: FCM sample selection optimization for Korean melting test - material grouping + risk classification to reduce sample count by 40-60%
tags: [fcm, korea, melting-test, certification, compliance, sample-selection]
created: 2026-04-16
---

# FCM Sample Selection Matrix for Korean Melting Test

**Domain**: Food Contact Material (FCM) testing, Korean import requirements  
**Trigger**: Processing FCM material lists for sample selection optimization

---

## Overview

This skill implements the optimal sample selection strategy for Korean melting test / FCM compliance testing. It reduces sample count by 40-60% while maintaining compliance coverage through material grouping and risk-based classification.

---

## When to Use

- Korean customer requests melting test for cooking equipment
- Need to submit FCM samples for import clearance
- Have 20+ materials/parts to evaluate
- Want to minimize testing cost while avoiding clearance risks

---

## Input Requirements

1. **FCM Material List** (Excel .xlsx or .xls format) containing:
   - Part name / technical name
   - Material type (e.g., Silicone, POM, Tritan, SUS304)
   - Food contact status (Yes / indirect / non-contact)
   - Use temperature
   - Contact time
   - Food type (water, oil, sauce, etc.)
   - Color
   - Supplier (optional but recommended)

2. **Background Context**:
   - Is this for official import record?
   - Does Korea accept mainland China test reports?
   - Any specific customer requirements?

---

## Classification Strategy

### A Class (Mandatory Samples) - 必须送样
**Criteria** (any one triggers A class):
- Direct food contact (FCM = "Yes")
- Silicone / rubber materials
- PTFE / Teflon coatings
- Seals / gaskets / O-rings
- Nozzles / tubes / pipes in food path
- Container bodies (boxes, lids with direct contact)
- High temperature (>200°C)
- Contact with oil / acidic liquids

**Action**: Submit individually for testing

### B Class (Representative Coverage) - 代表件覆盖
**Criteria** (all must be true):
- Same material as an A-class part
- Same color
- Same supplier / grade / formulation
- Same manufacturing process
- Use conditions NOT more severe than representative

**Action**: Covered by A-class representative, do NOT submit separately

### C Class (Excluded) - 暂不送样
**Criteria** (all must be true):
- No food contact (FCM = non-contact)
- No steam / condensate / splash exposure
- Structural parts only (housing, handles, external frames)
- Clear evidence of isolation from food path

**Action**: Exclude from testing (requires Korean side confirmation)

### D Class (Needs Confirmation) - 待确认
**Criteria**:
- Missing material information
- Unclear contact path
- Uncertain whether Korea accepts representative logic
- Special materials requiring expert review

**Action**: List separately, get Korean side confirmation before proceeding

---

## Execution Steps

### Step 1: Read and Parse Excel Files
```python
# For .xlsx files
from openpyxl import load_workbook
wb = load_workbook('file.xlsx', data_only=True)
ws = wb.active

# For .xls files
import xlrd
wb = xlrd.open_workbook('file.xls')
ws = wb.sheet_by_index(0)
```

### Step 2: Extract Key Fields
Required columns:
- Part name / technical name
- Material (Raw material technical name)
- FCM contact status (Yes/indirect)
- Temperature
- Color
- Supplier

### Step 3: Apply Classification Rules
```python
def classify_part(row):
    material = row.get('Material', '').lower()
    fcm = row.get('FCM', '').lower()
    temp = row.get('Temperature', '').lower()
    part_name = row.get('PartName', '').lower()
    
    # A class conditions
    if fcm == 'yes':
        if any(x in material for x in ['silicone', 'rubber', 'ptfe', 'teflon']):
            return 'A'  # High-risk material
        if any(x in part_name for x in ['gasket', 'seal', 'nozzle', 'tube']):
            return 'A'  # Critical parts
        if '200' in temp or '300' in temp:
            return 'A'  # High temperature
        return 'A'  # Direct contact
    
    # B class (indirect contact, can be covered)
    if fcm in ['indirect', 'indrect']:
        return 'B'
    
    # D class (needs confirmation)
    return 'D'
```

### Step 4: Group by Material
```python
from collections import defaultdict
groups = defaultdict(list)
for part in parts:
    key = f"{material}|{color}|{fcm_status}"
    groups[key].append(part)
```

### Step 5: Select Representatives
For each material group:
- High-risk parts → All go to A class
- Low-risk parts → Select 1 representative for A class, rest to B class

### Step 6: Generate Report
Output Markdown report with:
- Summary statistics (total, A/B/C/D counts, reduction rate)
- A-class list grouped by material
- B-class mapping table (which part covers which)
- Email template for Korean side confirmation
- Risk warnings
- Execution checklist

---

## Output Template

```markdown
# Korean Melting Test Sample Selection Matrix

**Generated**: {date}
**Source**: {file_name} ({total} parts)
**Strategy**: Material grouping + Risk assessment + Representative coverage

## Summary

| Class | Count | Description | Action |
|-------|-------|-------------|--------|
| A | {n} | Mandatory samples | Submit individually |
| B | {n} | Covered by representative | Do NOT submit |
| C | {n} | Excluded | Confirm with Korea |
| D | {n} | Needs confirmation | Pending review |

**Reduction Rate**: {total} → {A_count} ({pct}% reduction)

## A-Class List (by Material)
[Detailed list grouped by material type]

## B-Class Mapping
[Which parts are covered by which representatives]

## Email Template for Korean Confirmation
[Pre-written email for Korean side review]

## Next Steps
1. Internal review (R&D/Structural)
2. Certification team audit
3. Send to Korean side for written confirmation
4. Prepare samples per confirmation
```

---

## Critical Success Factors

### 1. Never Skip Written Confirmation
- Internal classification is NOT final
- MUST get Korean testing agency / importer / customer written approval
- Email confirmation is minimum requirement

### 2. Conservative on High-Risk Parts
- When in doubt, classify as A
- Silicone/rubber always A class
- Seals/gaskets always A class
- High temperature (>200°C) always A class

### 3. Document Everything
- Each B-class part must have clear representative mapping
- Each C-class exclusion must have evidence
- Keep full material list as appendix

### 4. Common Pitfalls
- ❌ Different colors in same group → Must separate
- ❌ Different suppliers in same group → Must separate
- ❌ Coated vs uncoated in same group → Must separate
- ❌ Assuming China test reports accepted → Confirm first

---

## Files to Save

1. `docs/韩国_melting_test_送样筛选矩阵.md` - Main report
2. `data/fcm_classification_result.json` - Raw classification data
3. `docs/TASK_BOARD.md` - Updated with T400 series tasks
4. `docs/progress.md` - Session summary

---

## Related Skills

- `clm-session-completion-workflow` - For updating docs + git commit
- `project-governance-setup` - For 5-layer governance structure

---

## Example Usage

```python
# This skill was used for:
# - 213 FCM parts from Korean customer
# - Classified into 95 A-class + 80 B-class
# - 46% sample reduction (213→95)
# - 19 material types, 43 material groups
# - Top materials: Silicone (29), POM (16), Tritan (14), PP (9), SUS304 (7)
```

---

*Last updated: 2026-04-16*
*Used in: 小淼 (XiaoMiao) certification agent project*
