---
name: feishu-document-batch-download
description: 批量下载飞书文档/知识库到本地 Markdown 格式
category: productivity
tags: [feishu, lark, document, backup, api]
created: 2026-04-15
---

# Feishu Document Batch Download

批量下载飞书文档/知识库到本地 Markdown 格式。

## 触发条件

- 需要备份飞书知识库/云文档到本地
- 同事离职交接，需要保存文档
- 需要批量导出飞书文档为 Markdown/PDF

## 前置要求

### 1. 飞书开放平台应用配置

必须有以下权限才能通过 API 下载文档：

| 权限 | 用途 | API 端点 |
|------|------|---------|
| `docx:document` 或 `docx:document:readonly` | 读取云文档 | `/docx/v1/documents/{id}/raw_content` |
| `wiki:wiki` 或 `wiki:wiki:readonly` | 读取知识库 | `/wiki/v1/nodes/{id}/content` |
| `drive:drive` | 获取文件列表 | `/drive/v1/files` |

### 2. 权限申请步骤

1. 打开飞书开放平台：https://open.feishu.cn/
2. 进入「企业管理」→「应用开发」
3. 找到或创建应用，记录 `App ID` 和 `App Secret`
4. 点击「权限管理」
5. 搜索并添加上述权限
6. **关键：点击「申请」后必须点击「发布」或「保存」**
7. 等待 1-2 分钟权限生效

### 3. 权限申请链接（快捷方式）

```
https://open.feishu.cn/app/{APP_ID}/auth?q=docx:document,wiki:wiki&op_from=openapi&token_type=tenant
```

## 操作步骤

### Step 1: 获取 Tenant Access Token

```python
import requests

APP_ID = "cli_xxxxxxxxxxxxx"
APP_SECRET = "xxxxxxxxxxxxxxxxxxxxx"

token_url = "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal"
resp = requests.post(token_url, json={
    "app_id": APP_ID,
    "app_secret": APP_SECRET
}, timeout=30)

result = resp.json()
if result.get("code") == 0:
    TOKEN = result["tenant_access_token"]
else:
    raise Exception(f"Token 获取失败：{result}")
```

### Step 2: 获取文档列表

```python
headers = {"Authorization": f"Bearer {TOKEN}"}

# 如果有文件夹 Token
url = "https://open.feishu.cn/open-apis/drive/v1/files"
params = {"folder_token": "FOLDER_TOKEN_HERE", "page_size": 50}
resp = requests.get(url, headers=headers, params=params)
files = resp.json().get("data", {}).get("files", [])
```

### Step 3: 批量下载文档

```python
import time
from pathlib import Path

DOWNLOAD_DIR = Path("./feishu-docs-backup")
DOWNLOAD_DIR.mkdir(parents=True, exist_ok=True)

for file in files:
    file_type = file.get("type")
    file_name = file.get("name")
    file_token = file.get("token") or file.get("obj_token")
    
    # 根据类型选择 API
    if file_type in ["docx", "doc"]:
        api_url = f"https://open.feishu.cn/open-apis/docx/v1/documents/{file_token}/raw_content"
    elif file_type == "wiki":
        api_url = f"https://open.feishu.cn/open-apis/wiki/v1/nodes/{file_token}/content"
    elif file_type == "sheet":
        api_url = f"https://open.feishu.cn/open-apis/sheets/v2/spreadsheets/{file_token}"
    else:
        continue
    
    resp = requests.get(api_url, headers=headers, timeout=30)
    
    if resp.status_code == 200:
        filename = f"{file_name}.md"
        with open(DOWNLOAD_DIR / filename, "w", encoding="utf-8") as f:
            try:
                content = resp.json()
                f.write(json.dumps(content, ensure_ascii=False, indent=2))
            except:
                f.write(resp.text)
        print(f"✅ {filename}")
    
    time.sleep(0.3)  # 限速
```

## 常见问题

### Q1: API 返回 403 forbidden

**原因：** 权限未开通或未发布

**解决：**
1. 确认应用已开通所需权限
2. 确认已点击「发布」按钮
3. 等待 1-2 分钟权限生效
4. 重新获取 Token（旧 Token 可能缓存旧权限）

### Q2: API 返回 404

**原因：** 
- Wiki 文档 API 端点可能不同（飞书有多个版本）
- 文档 Token 不正确

**解决：**
- 尝试 `/wiki/v1/nodes/{id}` 或 `/wiki/v2/nodes/{id}`
- 从文档 URL 提取正确的 Token（最后一段）

### Q3: Cookie 方式为什么不可靠？

飞书 Cookie 有效期仅 **5-10 分钟**，批量下载时会过期。

**推荐方案：** 使用 Open API + 机器人权限

### Q4: 浏览器扫码登录为什么失败？

无头浏览器的二维码会快速过期（通常 1-2 分钟），用户来不及扫描。

**推荐方案：** 使用 Open API

## 完整脚本模板

```python
#!/usr/bin/env python3
"""
飞书文档批量下载工具
使用前请确保：
1. 已创建飞书开放平台应用
2. 已开通 docx:document 和 wiki:wiki 权限
3. 已发布应用并等待 1-2 分钟
"""

import requests
import json
import time
from pathlib import Path
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# 配置
APP_ID = "cli_xxxxxxxxxxxxx"
APP_SECRET = "xxxxxxxxxxxxxxxxxxxxx"
DOWNLOAD_DIR = Path("./feishu-docs-backup")

# 获取 Token
token_resp = requests.post(
    "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal",
    json={"app_id": APP_ID, "app_secret": APP_SECRET},
    timeout=30,
    verify=False
)
TOKEN = token_resp.json()["tenant_access_token"]
headers = {"Authorization": f"Bearer {TOKEN}"}

# 下载目录
DOWNLOAD_DIR.mkdir(parents=True, exist_ok=True)

# 文档列表（从 URL 提取或从 Drive API 获取）
doc_urls = [
    "https://v56fodkhr4.feishu.cn/docx/xxxxx",
    "https://v56fodkhr4.feishu.cn/wiki/xxxxx",
]

for url in doc_urls:
    doc_id = url.split("/")[-1]
    doc_type = url.split("/")[3]
    
    if doc_type == "docx":
        api_url = f"https://open.feishu.cn/open-apis/docx/v1/documents/{doc_id}/raw_content"
    elif doc_type == "wiki":
        api_url = f"https://open.feishu.cn/open-apis/wiki/v1/nodes/{doc_id}/content"
    
    resp = requests.get(api_url, headers=headers, timeout=30, verify=False)
    
    if resp.status_code == 200:
        filename = f"{doc_type}_{doc_id}.md"
        with open(DOWNLOAD_DIR / filename, "w", encoding="utf-8") as f:
            f.write(resp.text)
        print(f"✅ {filename}")
    
    time.sleep(0.3)
```

## 备选方案

如果 API 权限无法开通，使用以下备选：

### 方案 A：飞书客户端手动导出
1. 打开飞书桌面客户端
2. 进入文档
3. 点 `···` → `导出为` → `Markdown/Word/PDF`

### 方案 B：SingleFile 浏览器扩展
1. 安装 Chrome 扩展「SingleFile」
2. 打开每个文档
3. 点扩展图标保存完整页面

## 相关文件

- 下载目录：`./feishu-docs-backup/`
- 日志文件：`download_log.json`
- 报告文件：`DOWNLOAD_REPORT.md`
