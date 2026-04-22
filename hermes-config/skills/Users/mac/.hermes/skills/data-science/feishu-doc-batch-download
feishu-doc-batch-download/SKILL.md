---
name: feishu-doc-batch-download
description: 批量下载飞书文档 - 使用 Cookie 或 API 方式下载飞书知识库/云文档及其所有子文档
category: data-science
---

# 飞书文档批量下载

## 适用场景
- 同事离职交接，需要快速备份飞书知识库所有文档
- 批量归档飞书云文档（Wiki/DocX/Sheet 等）
- 离线保存飞书文档内容

## 前置条件

### 方案 A：Cookie 方式（最快，但 Cookie 易过期）
1. 用户能在浏览器正常访问飞书文档
2. 需要从浏览器复制 Cookie

### 方案 B：飞书开放平台 API（稳定，但需要配置权限）
1. 需要飞书开放平台应用（AppID + AppSecret）
2. 需要开通以下权限：
   - `drive:drive` 或 `drive:drive:readonly`（云文档读取）
   - `docx:document` 或 `docx:document:readonly`（文档读取）
   - `wiki:wiki`（知识库读取）

## 操作步骤

### 方案 A：Cookie 方式

#### 1. 获取 Cookie
```
1. 在浏览器打开飞书文档
2. 按 F12 打开开发者工具
3. 点 Console 标签
4. 输入：document.cookie
5. 复制全部输出
```

#### 2. 运行下载脚本
```python
import requests
from pathlib import Path
import re

COOKIE = "<用户提供的 Cookie>"
TARGET_URL = "https://v56fodkhr4.feishu.cn/wiki/<DOC_TOKEN>"
DOWNLOAD_DIR = Path("./feishu-docs-backup")

headers = {
    "Cookie": COOKIE,
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
}

# 下载主文档
response = requests.get(TARGET_URL, headers=headers, timeout=30, verify=False)
with open(DOWNLOAD_DIR / "main_page.html", "wb") as f:
    f.write(response.content)

# 提取所有子文档链接
doc_links = re.findall(r'https://[^/]+\.feishu\.cn/(?:wiki|docx|doc|sheet|file)/[A-Za-z0-9]+', response.text)
unique_links = list(set(doc_links))

# 批量下载子文档
for url in unique_links:
    response = requests.get(url, headers=headers, timeout=30, verify=False)
    doc_id = url.split("/")[-1]
    with open(DOWNLOAD_DIR / f"{doc_id}.html", "wb") as f:
        f.write(response.content)
```

#### 3. 注意事项
- ⚠️ Cookie 有效期短（约 5-10 分钟），需快速操作
- ⚠️ 如检测到登录页，说明 Cookie 已失效，需重新获取
- ⚠️ 添加 `time.sleep(1)` 限速，避免被封

### 方案 B：API 方式

#### 1. 配置飞书开放平台权限
```
1. 访问 https://open.feishu.cn/
2. 进入「企业管理」→「应用开发」
3. 找到应用（AppID）
4. 点「权限管理」
5. 搜索并添加：drive:drive, docx:document, wiki:wiki
6. 点击「发布」保存
```

#### 2. 获取 Token
```python
import requests

APP_ID = "cli_xxx"
APP_SECRET = "xxx"

token_url = "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal"
resp = requests.post(token_url, json={"app_id": APP_ID, "app_secret": APP_SECRET})
TOKEN = resp.json()["tenant_access_token"]
```

#### 3. 获取文档列表
```python
headers = {"Authorization": f"Bearer {TOKEN}"}
url = "https://open.feishu.cn/open-apis/drive/v1/files"
params = {"folder_token": "<FOLDER_TOKEN>", "page_size": 100}
resp = requests.get(url, headers=headers, params=params)
files = resp.json()["data"]["files"]
```

#### 4. 下载单个文档
```python
# DocX API
doc_url = f"https://open.feishu.cn/open-apis/docx/v1/documents/{DOC_TOKEN}"
resp = requests.get(doc_url, headers=headers)
content = resp.json()
```

## 常见问题

### Q: Cookie 方式返回登录页
**A:** Cookie 已过期，需重新获取。建议在获取 Cookie 后立即运行脚本。

### Q: API 返回 403 Forbidden
**A:** 应用缺少权限，需到飞书开放平台开通对应权限。

### Q: API 返回 404
**A:** 可能是 API 端点错误。飞书有多个 API 版本（V1/V2），需尝试不同端点。

### Q: SSL 错误（UNEXPECTED_EOF_WHILE_READING）
**A:** 网络不稳定，添加重试机制：
```python
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

session = requests.Session()
retry = Retry(total=3, backoff_factor=2, status_forcelist=[500, 502, 503, 504])
adapter = HTTPAdapter(max_retries=retry)
session.mount("https://", adapter)
```

### Q: 下载后文件是空的
**A:** 可能是权限不足或 Cookie 失效。检查响应内容是否包含"login"或"登录"关键词。

## 输出结构
```
feishu-docs-backup/
├── main_page.html          # 主文档 HTML
├── doc_links.txt           # 提取的文档链接列表
├── download_log.json       # 下载日志（成功/失败状态）
├── DOWNLOAD_REPORT.md      # 下载报告（摘要）
└── docs/                   # 子文档目录
    ├── wiki_xxx.html
    ├── docx_xxx.html
    └── ...
```

## 最佳实践
1. **优先用 API 方式**：更稳定，适合大量文档
2. **Cookie 方式用于紧急场景**：快速获取，但需立即执行
3. **添加限速**：每请求间隔 1-2 秒，避免被封
4. **保存下载日志**：记录成功/失败，便于后续重试
5. **权限配置要完整**：drive + docx + wiki 权限都要开通
