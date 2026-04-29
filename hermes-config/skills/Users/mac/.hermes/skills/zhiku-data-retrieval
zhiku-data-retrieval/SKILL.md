---
name: zhiku-data-retrieval
category: data-science
description: 智库 Agent — 公司后台 MySQL 数据库的专属数据检索与规整专家，覆盖 btyc/dev_btyc/manage_backend/schedule 等 6 个库
---

# 🤖 智库 Agent - 后台数据检索与规整

**激活日期：** 2026-04-29  
**角色定位：** 公司后台数据库专属数据检索与规整专家  
**数据源：** MySQL 腾讯云 CDB（只读）  
**工程路径：** ~/Projects/zhiku-agent/

---

## 🎯 核心职责

### 1. 数据检索
- 针对公司后台 MySQL 数据库执行 SQL 查询
- 覆盖 6 个库：btyc / btyc_statics / dev_btyc / manage_backend / schedule / schedule2
- 支持单表查询、多表 JOIN、聚合统计、时间序列分析

### 2. 数据规整
- 将查询结果整理为可读格式（表格、统计摘要、趋势分析）
- 输出 CSV/JSON/Markdown 格式
- 结果保存到 ~/Projects/zhiku-agent/output/

### 3. 链路分析
- 追踪 工程师 → 客户/门店 → 设备 → 菜谱 → 执行日志 的关联关系
- 分析数据完整性和质量

---

## 📁 项目结构

```
~/Projects/zhiku-agent/
├── config/
│   └── db_config.env          # 数据库连接配置（明文密码，不入 Git）
├── docs/
│   ├── 00-PROJECT-INDEX.md    # 项目索引
│   ├── progress.md            # 进度日志
│   ├── TASK_BOARD.md          # 任务看板
│   └── RESOURCE.md            # 资源注册表（数据库/表索引）
├── scripts/
│   ├── query.py               # SQL 查询工具
│   ├── explore_schema.py      # Schema 自动探索
│   └── sn_investigation.py    # SN 设备深度调查脚本（含猪油成分分析）
├── .venv/                     # Python 虚拟环境（pymysql）
├── output/                    # 查询结果输出（CSV/JSON）
└── README.md
```

---

## 🔧 使用方法

### 方式 1：直接 SQL 查询
```bash
cd ~/Projects/zhiku-agent
python3 scripts/query.py "SELECT * FROM btyc.ums_admin LIMIT 10"
```

### 方式 2：Schema 探索
```bash
# 探索单个库
python3 scripts/explore_schema.py btyc

# 探索所有库
python3 scripts/explore_schema.py
```

### 方式 3：Python 内联查询
```python
import pymysql
conn = pymysql.connect(host='sh-cdbrg-eoqkyx9i.sql.tencentcdb.com', port=28028,
                       user='btyc_hw_read', password='qQT!kv*62pA9^V',
                       charset='utf8mb4', cursorclass=pymysql.cursors.DictCursor)
# ... 执行查询
conn.close()
```

---

## 📋 关键数据库与核心表

### btyc（281 表）— 核心业务库
| 表名 | 用途 |
|------|------|
| ums_admin | 管理员/工程师账户（id, full_name, phone_num, company_id） |
| auth_user | 认证用户（id, username, nickname, mobile, feishu_id） |
| ums_company | 门店/客户（id, company_name） |
| sop_recipe | 菜谱（id, create_user, update_user, recipe_name） |
| sop_machinelog | 设备烹饪日志（recipe_id, sn, owner, username, create_time） |
| sop_robot | 设备信息（machinecode, company_id） |
| btyc_user_session | 用户会话（user_id, machine_code） |
| main_recipe | 主菜谱 |
| recipe_detail | 菜谱详情 |

### btyc_statics（7 表）— 统计数据库
| 表名 | 用途 |
|------|------|
| store_statistics | 门店统计 |
| robot_cook_stat | 机器人烹饪统计 |
| robot_cook_day | 机器人按天烹饪统计 |

### dev_btyc（278 表）— 开发环境
| 表名 | 用途 |
|------|------|
| btyc_user_session | 用户会话 |
| oms_merchant_cooking_log | 商户烹饪日志（需跨库查询） |
| bytc_malfunctions_info | 故障信息 |

### manage_backend（18 表）— 管理后台
| 表名 | 用途 |
|------|------|
| main_company | 公司信息 |
| main_user | 管理后台用户 |
| main_recipe | 管理后台菜谱 |
| recipe_detail | 菜谱详情 |

### schedule / schedule2（25/23 表）— 调度系统
| 表名 | 用途 |
|------|------|
| oms_merchant_cooking_log | 商户烹饪日志 |
| oms_merchant_machine_info | 商户设备信息 |
| oms_merchant_recipe_conf | 商户菜谱配置 |

---

## 📋 数据库字段映射与避坑指南 (重要!)

**这些字段名与预期不符，直接查会报错：**

| 预期表 | 预期字段 | **实际字段** | 说明 |
|--------|----------|--------------|------|
| `btyc.sop_machinelog` | `cook_time` | **`time`** | 烹饪耗时 |
| `btyc.sop_machinelog` | `status` | **无此字段** | 状态可能在 `component` 或其他表 |
| `btyc.sop_machinelog` | `username` | **`username`** | 存在 |
| `btyc.base_ingredients` | `name` | **`ingredients_name`** | 食材名称 |
| `btyc.bytc_robot_malfunctions_log` | `error_msg` | **`second_level_error_details`** | 故障详情 |
| `btyc.robot_conservation_pot_log` | `machine_code` | **`machine_code`** | 存在，注意不是 `sn` |
| **Recipe Detail** | `btyc.sop_recipe` | **`manage_backend.main_recipe`** | **关键！** 菜谱步骤(`steps_describe`)和配料(`ingredients_total_dosage`)在 `manage_backend` 库，不在 `btyc` |

## 🔗 已验证的关系链路

根据 ENGINEER_DB_DISCOVERY_v1.md：

1. **工程师 → 菜谱 → 烹饪日志 → 门店**
   `ums_admin.id → sop_recipe(create_user) → sop_machinelog(recipe_id, sn, owner) → ums_company(id=owner)`

2. **工程师 → 会话 → 设备 → 门店**
   `ums_admin.id → btyc_user_session(user_id, machine_code) → sop_robot(machinecode, company_id) → ums_company`

3. **用户 → 角色 → 公司**
   `auth_user → auth_user_role_rel → auth_role`
   `ums_admin → ums_role`
   `ums_admin → ums_company(company_id)`

---

## 📊 常用查询模板

### 查询工程师信息
```sql
-- 按姓名搜索工程师
SELECT id, username, full_name, phone_num, company_id 
FROM btyc.ums_admin 
WHERE full_name LIKE '%张三%' OR username LIKE '%张三%';

-- 工程师关联角色
SELECT a.id, a.full_name, r.name as role_name
FROM btyc.ums_admin a
LEFT JOIN btyc.ums_role r ON a.role_id = r.id;
```

### 查询门店/客户
```sql
-- 所有门店
SELECT id, company_name FROM btyc.ums_company ORDER BY id;

-- 关联工程师与门店
SELECT a.full_name, c.company_name
FROM btyc.ums_admin a
LEFT JOIN btyc.ums_company c ON a.company_id = c.id;
```

### 查询菜谱
```sql
-- 工程师创建的菜谱
SELECT r.id, r.name, r.create_user, a.full_name
FROM btyc.sop_recipe r
LEFT JOIN btyc.ums_admin a ON r.create_user = a.id
ORDER BY r.id DESC LIMIT 20;
```

### 查询烹饪日志
```sql
-- 某门店的设备烹饪日志
SELECT m.sn, m.recipe_id, m.username, m.create_time
FROM btyc.sop_machinelog m
WHERE m.owner = 门店ID
ORDER BY m.create_time DESC LIMIT 20;
```

### 跨库查询（工程师 → 烹饪日志）
```sql
-- 注意：可能需要分别查询后关联
-- 先从 btyc 获取工程师关联的设备/门店
-- 再从 schedule 查询对应的烹饪日志
```

---

## ⚠️ 注意事项（含实战发现的关键坑点）

1. **只读权限** — 账号为 btyc_hw_read，只能 SELECT，不能 INSERT/UPDATE/DELETE
2. **数据量控制** — 大表查询务必加 LIMIT，避免超时
3. **字符编码** — 使用 utf8mb4，确保中文正常显示
4. **跨库 JOIN** — 部分库可能不支持跨库 JOIN，需要分步查询
5. **结果输出** — 所有查询结果自动保存到 output/ 目录
6. **密码安全** — db_config.env 不入 Git，.gitignore 已配置

### ⚡ 关键实战发现（2026-04-29 更新）

#### 坑点 1：菜谱表分裂 — sop_machinelog 的 recipe_id 不在 btyc.sop_recipe 中
`sop_machinelog.recipe_id`（如 212423）在 `btyc.sop_recipe` 中查不到！
**菜谱详情在 `manage_backend.main_recipe` 中**，而非 `btyc.sop_recipe`。
```python
# ❌ 错误：btyc.sop_recipe 中查不到 212423
# ✅ 正确：去 manage_backend 查
cursor.execute('SELECT id, name, steps_describe, ingredients_total_dosage FROM manage_backend.main_recipe WHERE id=%s', (recipe_id,))
```
注意：`btyc.recipe_detail` 表不存在，recipe_detail 只在 manage_backend 中。

#### 坑点 2：字段名与实际不符（必须先用 SHOW COLUMNS 确认）
- `btyc.base_ingredients` → 字段是 `ingredients_name`，不是 `name`
- `btyc.bytc_robot_malfunctions_log` → 字段是 `second_level_error_details`，不是 `error_msg`
- `btyc.sop_machinelog` → **没有** `cook_time` 和 `status` 字段！
- `btyc.sop_recipe` 无 `ingredients_json` / `cook_steps_json` 字段，只有 `steps_describe` 和 `ingredients_total_dosage`
**规则：查询前先执行 SHOW COLUMNS 确认字段名**

#### 坑点 3：Python f-string 中 SQL LIKE 的 % 转义
在 f-string 中写 SQL LIKE 时，`%` 会被 Python 当作格式化占位符，必须写成 `%%`：
```python
# ❌ 错误：Python 把 %s 和 %油% 混淆
cursor.execute(f"SELECT * FROM t WHERE sn = %s AND col LIKE '%油%'", (sn,))

# ✅ 正确：用 %% 转义 LIKE 通配符
cursor.execute(f"SELECT * FROM t WHERE sn = %s AND col LIKE '%%油%%'", (sn,))
```

#### 坑点 4：SN 号格式差异
用户提供的 SN（如 `105222512010046`）在数据库中实际存储为 `0105222512010046`（带前导 0）。
**查询时用 LIKE 匹配**：`WHERE machinecode LIKE '%105222512010046'`

#### 坑点 5：Python 环境
系统 Python 3.14 受 PEP 668 保护，必须使用项目虚拟环境：
```bash
cd ~/Projects/zhiku-agent && .venv/bin/python3 scripts/query.py "..."
```

---

## 🔄 工作流程

```
用户需求 → 理解检索意图 → 编写 SQL → 执行查询 → 
数据规整（表格/统计/趋势） → 输出结果 → 保存到 output/
```

### 复杂查询流程
```
分析需求 → 确定涉及的库和表 → 探索表结构（explore_schema.py） →
编写 SQL（可能需要多步） → 验证结果 → 规整输出 → 生成分析报告
```

---

## 📝 输出规范

### 查询结果输出
- 默认格式：终端表格显示（前 50 行）
- 文件保存：CSV（UTF-8 with BOM，Excel 兼容）
- 文件名：query_YYYYMMDD_HHMMSS.csv

### 分析报告输出
- Markdown 格式
- 包含：查询目的、SQL 语句、结果摘要、分析结论
- 保存到 output/ 目录

---

## 📝 报告输出规范 (默认)

- **输出目录：** `~/Documents/MySQL/`
- **文件名格式：** `report_{SN}.md`
- **内容要求：** 
  - 必须包含原始数据明细表（Markdown Tables）
  - 必须包含“生产周期与间隔分析”（计算两次 `create_time` 之间的时间差）
  - 必须包含设备基础档案 (`sop_robot`)
  - 必须包含故障与维护原始记录
  - 结论放在报告末尾，而非开头

## 🎯 典型工作场景

1. **日常数据检索** — 用户问"查一下 XX 工程师今天做了什么"，执行对应查询
2. **设备 SN 深度调查** — 针对指定 SN 输出全生命周期报告到 `~/Documents/MySQL/`，包含间隔分析
3. **数据规整** — 将原始查询结果整理为 Markdown 表格输出
4. **链路追踪** — 注意跨库 JOIN 限制，先查 `manage_backend` 获取详情再回 `btyc` 关联
5. **数据质量检查** — 检查关键字段完整性、关联关系是否成立
6. **SN 设备深度调查** — 按设备 SN 号追踪：主档案 → 烹饪日志 → 菜谱成分 → 维护/故障记录 → 配置快照
7. **特定成分溯源** — 查询某段时间内设备是否使用了特定食材（如猪油），需交叉比对 machinelog → main_recipe → 配料表

---

## 🔗 相关技能与文档

- `multi-project-coordination` — 多项目协调
- `clm-project-governance` — CLM 项目治理
- `ENGINEER_DB_DISCOVERY_v1.md` — 工程师数据库发现记录
- `DATA_HANDOVER_v1.md` — 数据交接文档

---

## 📋 实战案例：SN 设备成分溯源流程

**场景**：用户想知道某台设备是否在特定菜谱中使用了某成分（如猪油桶）

**步骤**：
1. 用 `LIKE '%SN%'` 在 `btyc.sop_robot` 定位设备真实 SN
2. 从 `btyc.sop_machinelog` 提取该 SN 近期执行的 recipe_id 列表
3. **关键**：用这些 recipe_id 去 `manage_backend.main_recipe` 查（不是 btyc.sop_recipe！）
4. 检查 `name`、`steps_describe`、`ingredients_total_dosage` 字段是否包含目标成分关键词
5. 检查 `btyc.base_ingredients` 确认该成分在系统中的标准命名（如 ingredients_name LIKE '%猪油%'）
6. 交叉比对 `robot_conservation_pot_log`（维护日志）和 `bytc_robot_malfunctions_log`（故障日志）
7. 检查 `btyc.robot_config_info.config` JSON 中的 potType 等配置参数
