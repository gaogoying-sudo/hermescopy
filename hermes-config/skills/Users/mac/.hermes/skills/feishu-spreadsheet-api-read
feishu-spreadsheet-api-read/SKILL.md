---
name: feishu-spreadsheet-api-read
description: Read Feishu (飞书) spreadsheet content via Open API using tenant_access_token
category: productivity
---

# Feishu Spreadsheet API Read

读取飞书电子表格内容的标准流程。适用于飞书开放平台 API 方式读取（非浏览器方式）。

## 适用场景

- 需要程序化读取飞书表格数据
- 浏览器无法访问（需要登录态）
- 批量读取或自动化场景

## 前置条件

需要飞书应用的 APP_ID 和 APP_SECRET（从 memory 或配置中获取）：
```
APP_ID: cli_a92b81d03838dbb3
APP_SECRET: TO17YrJH0FmJdNqkw2ybhgSpMqS8YK0c
```

## 步骤

### 1. 获取 tenant_access_token

```python
import requests

APP_ID = "cli_a92b81d03838dbb3"
APP_SECRET = "TO17YrJH0FmJdNqkw2ybhgSpMqS8YK0c"

token_url = "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal"
resp = requests.post(token_url, json={"app_id": APP_ID, "app_secret": APP_SECRET})
token = resp.json()["tenant_access_token"]
```

### 2. 从 URL 提取 spreadsheet_token 和 sheet_id

URL 格式：`https://v56fodkhr4.feishu.cn/sheets/{SPREADSHEET_TOKEN}?sheet={SHEET_ID}`

- spreadsheet_token: URL 路径中的长字符串（如 `CB2msa6bGhf7dDt8xdMcBzbonXd`）
- sheet_id: URL 参数 `?sheet=` 后的值（如 `c01gDa`）

**注意：** sheet_id 不是标准的 "Sheet1"、"0" 等，而是飞书内部的随机字符串（如 `c01gDa`）。必须从 URL 中获取。

### 3. 读取表格数据

**使用 GET 方法 + query params（不要用 POST，会 404）：**

```python
headers = {
    "Authorization": f"Bearer {token}",
    "Content-Type": "application/json; charset=utf-8"
}

spreadsheet_token = "CB2msa6bGhf7dDt8xdMcBzbonXd"
sheet_id = "c01gDa"

batch_get = f"https://open.feishu.cn/open-apis/sheets/v2/spreadsheets/{spreadsheet_token}/values_batch_get"
resp = requests.get(batch_get, headers=headers, params={
    "ranges": [f"{sheet_id}!A1:Z500"]  # 格式: {sheet_id}!{range}
})
result = resp.json()
```

### 4. 解析单元格数据

飞书单元格返回的是富文本结构，需要清理：

**单元格数据类型：**
- `None` — 空单元格
- `list` — 富文本单元格（含多个文本片段、@提及、链接等）
- `dict` — 单个富文本元素
- `str/int/float` — 纯文本/数字

**常见 dict 字段：**
- `text` — 显示文本
- `link` — 链接地址
- `type` — 类型（`"url"`, `"mention"`, `"text"` 等）
- `mentionType` — @提及类型（8=多维表格, 22=知识库等）
- `token` — 被提及对象的 token

```python
def clean_cell(cell):
    if cell is None:
        return ""
    elif isinstance(cell, list):
        texts = []
        for item in cell:
            if isinstance(item, dict):
                if "text" in item:
                    texts.append(item["text"].strip())
                elif "link" in item:
                    texts.append(item["link"])
            else:
                texts.append(str(item))
        return " ".join(texts)
    elif isinstance(cell, dict):
        if "text" in cell:
            return cell["text"].strip()
        elif "link" in cell:
            return cell["link"]
        else:
            return str(cell)
    else:
        return str(cell)

values = result["data"]["valueRanges"][0]["values"]
for i, row in enumerate(values):
    if row:
        cleaned = [clean_cell(c) for c in row]
        non_empty = [(j, v) for j, v in enumerate(cleaned) if v]
        if non_empty:
            print(f"R{i}: {non_empty}")
```

## 已知限制和坑（2026-04-22 更新）

| 问题 | 解决方案 | 状态 |
|------|---------|------|
| 浏览器无法访问（需要登录态） | 用 API 方式读取 | ✅ 已验证 |
| POST 方法返回 404 | 必须用 GET + query params | ✅ 已验证 |
| sheet_id 不是 "Sheet1" 等标准值 | 从 URL 的 `?sheet=` 参数获取 | ✅ 已验证 |
| `sheets/query` 返回 404 | 无法列出所有 sheet，只能从 URL 获取 | ✅ 已验证 |
| `drive/v1/files/{token}` 返回 404 | 用 Sheets API 而非 Drive API | ✅ 已验证 |
| `sheets/v3/spreadsheets/{token}/sheets` 返回 404 | v3 API 不可用，用 v2 | ✅ 已验证 |
| `sheets/v2/spreadsheets/{token}/sheets` 返回 404 | v2 sheets list 也不可用 | ✅ 已验证 |
| `bitable` API 需要额外权限 | 普通表格用 Sheets API，多维表格需要 bitable 权限 | ✅ 已验证 |
| `values_batch_get` POST 返回 404 | 必须用 GET + query params | ✅ 已验证 |
| 数据量过大超限（>10MB） | 返回 code=90221，需分块读取 | ✅ 已验证 |
| 单元格是富文本结构 | 需要 clean_cell 函数解析（含 mention、link 等） | ✅ 已验证 |

## 多 Sheet 处理（重要！）

**问题：** 一个电子表格（spreadsheet）可以包含多个子表（sheet），但 API 无法列出所有子表。

**解决方案：**
1. 从 URL 中获取每个 sheet 的 sheet_id（`?sheet=xxx`）
2. 对每个 sheet_id 分别调用 API
3. **无法通过 API 列出所有 sheet** — 以下端点均返回 404：
   - `GET /sheets/v2/spreadsheets/{token}/sheets/query`
   - `POST /sheets/v2/spreadsheets/{token}/sheets/query`
   - `GET /sheets/v3/spreadsheets/{token}/sheets`
   - `GET /drive/v1/files/{token}`

**常见 sheet_id 模式尝试（不保证有效）：**
```python
# 尝试常见命名模式
sheet_ids_to_try = ["c01gDa", "Sheet1", "Sheet2", "工作表1", "0", "1"]
for sid in sheet_ids_to_try:
    resp = requests.get(batch_get, headers=headers, params={
        "ranges": [f"{sid}!A1:Z50"]
    })
    result = resp.json()
    if result.get("code") == 0:
        print(f"Found sheet: {sid}")
```

**最佳实践：** 让用户在飞书网页版中点击不同子表，从 URL 中复制 sheet_id。

## 完整示例

```python
import requests
import json

def read_feishu_spreadsheet(url, app_id, app_secret):
    # Extract tokens from URL
    import re
    match = re.search(r'/sheets/([^?]+)\?sheet=([^&]+)', url)
    if not match:
        raise ValueError("Cannot extract spreadsheet_token and sheet_id from URL")
    spreadsheet_token, sheet_id = match.groups()
    
    # Get token
    token_resp = requests.post(
        "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal",
        json={"app_id": app_id, "app_secret": app_secret}
    )
    token = token_resp.json()["tenant_access_token"]
    
    headers = {"Authorization": f"Bearer {token}"}
    
    # Read data
    batch_url = f"https://open.feishu.cn/open-apis/sheets/v2/spreadsheets/{spreadsheet_token}/values_batch_get"
    resp = requests.get(batch_url, headers=headers, params={
        "ranges": [f"{sheet_id}!A1:Z500"]
    })
    result = resp.json()
    
    if result.get("code") != 0:
        raise Exception(f"API error: {result}")
    
    return result["data"]["valueRanges"][0]["values"]
```

## 调试建议

1. 先确认 token 获取成功（code=0）
2. 确认 spreadsheet_token 正确（用 metadata API 验证）
3. 确认 sheet_id 正确（从 URL 提取）
4. 从小范围开始读取（A1:Z10），确认数据格式
5. 逐步扩大范围
