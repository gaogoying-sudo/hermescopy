---
name: feishu-batch-document-export
description: Bulk export documents from Feishu (飞书) knowledge base/cloud docs - Chrome extension approach
version: 1.0.0
created: 2026-04-15
---

# 飞书文档批量导出技能

## 适用场景

需要从飞书知识库/云文档批量下载多个文档到本地，用于：
- 工作交接
- 数据备份
- 离线归档

## 方案对比

| 方案 | 成功率 | 效率 | 难度 | 推荐度 |
|------|--------|------|------|--------|
| API 自动化 | 15% (部分文档需授权) | 高 | 高 | ⭐⭐ |
| Cookie 批量下载 | 0% (Cookie 易过期) | 中 | 中 | ⭐ |
| **Chrome 插件** | **~90%** | **高** | **低** | ⭐⭐⭐⭐⭐ |
| 纯手动导出 | 100% | 低 | 低 | ⭐⭐⭐ |

## 推荐方案：Chrome 插件

### 为什么插件方案最有效

1. **利用用户现有登录状态** - 不需要 API 权限配置
2. **可视化操作** - 实时看到导出进度
3. **稳定可靠** - 不依赖易过期的 Cookie
4. **即装即用** - 无需复杂配置

### 插件核心功能

```javascript
// content.js - 页面注入脚本核心逻辑

// 1. 从页面提取文档列表
function extractDocList() {
  // 尝试侧边栏选择器
  const selectors = ['.wiki-menu-item', '.doc-menu-item', '[data-type="doc"]'];
  // 提取标题、URL、文档 ID
}

// 2. 导出单个文档
async function exportDoc(doc, format) {
  // 调用飞书导出 API 或提取页面内容
  // 触发浏览器下载
}

// 3. 批量导出控制
async function batchExport(docs, format) {
  // 遍历文档列表
  // 添加延迟避免反爬
  // 显示进度
}

// 4. 创建 UI 面板
function createControlPanel() {
  // 浮动按钮 + 导出控制面板
}
```

### 插件文件结构

```
feishu-batch-export-extension/
├── manifest.json       # Manifest V3 配置
├── content.js          # 核心功能脚本
├── popup.html/js       # 插件弹出界面
├── styles.css          # 样式
├── icon*.png           # 图标
└── README.md           # 使用说明
```

### manifest.json 关键配置

```json
{
  "manifest_version": 3,
  "permissions": ["activeTab", "downloads", "scripting"],
  "host_permissions": ["https://*.feishu.cn/*"],
  "content_scripts": [{
    "matches": ["https://*.feishu.cn/wiki/*", "https://*.feishu.cn/drive/*"],
    "js": ["content.js"],
    "run_at": "document_idle"
  }]
}
```

## 安装步骤

1. 打开 `chrome://extensions/`
2. 开启「开发者模式」
3. 点击「加载已解压的扩展程序」
4. 选择插件文件夹

## 使用流程

1. 打开飞书知识库/文档文件夹页面
2. 点击页面右下角「📥 批量导出」浮动按钮
3. 选择导出格式（Markdown/Word/PDF）
4. 点击「开始批量导出」
5. 等待完成，文件自动下载到 `~/Downloads/`

## 配置选项

在 `content.js` 中调整：

```javascript
const CONFIG = {
  exportFormat: 'markdown',      // 默认格式
  delayBetweenExports: 1000,     // 文档间延迟（毫秒）
  outputFolder: 'feishu-docs-export'
};
```

## 常见问题

### Q: API 方式为什么失败？
A: 飞书权限模型是两层的：
1. 应用需要有读取权限（docx:document）
2. 每个文档所有者需要单独授权给应用
即使应用有权限，未授权的文档仍返回 403

### Q: Cookie 方式为什么失败？
A: 飞书 Cookie 有效期仅 3-5 分钟，批量下载过程中会过期

### Q: Wiki 文档无法导出？
A: 飞书 Wiki API 支持有限，部分 Wiki 文档需手动导出

### Q: 只下载了部分文档？
A: 
- 增加 `delayBetweenExports` 避免触发反爬
- 检查是否有文档权限不足
- 分批导出（每次 10-20 个）

## 其他方案（备选）

### API 方式（需权限配置）

```python
# 仅适用于已授权给机器人的文档
import requests

TOKEN = get_tenant_access_token(APP_ID, APP_SECRET)
headers = {"Authorization": f"Bearer {TOKEN}"}

# 云文档 API
url = f"https://open.feishu.cn/open-apis/docx/v1/documents/{doc_id}/raw_content"
resp = requests.get(url, headers=headers)

# 知识库 API（部分不支持）
url = f"https://open.feishu.cn/open-apis/wiki/v1/nodes/{doc_id}/content"
```

**需要开通的权限：**
- `docx:document` 或 `docx:document:readonly`
- `wiki:wiki`（但 API 可能返回 404）

### 手动导出（最可靠但效率低）

1. 打开每个文档
2. 点右上角 `···` → `导出为` → 选择格式
3. 保存到本地

## 经验总结

1. **优先尝试插件方案** - 成功率最高，配置最简单
2. **API 适合自动化场景** - 但需要文档所有者授权
3. **Cookie 方式不可靠** - 过期太快，不推荐
4. **Wiki 文档是特殊情况** - 可能需要手动处理
5. **设置合理延迟** - 避免触发反爬机制（建议 1-2 秒）

## 扩展建议

- 断点续传：记录已导出文档
- 递归子文件夹：支持导出嵌套结构
- 导出元数据：作者、更新时间等
- 自动打包 ZIP：合并为单个压缩包
- 发布到 Chrome Web Store：方便分发
