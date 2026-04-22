_Learn about the person you're helping. Update this as you go._
§
**Name:**
§
**What to call them:**
§
**Pronouns:** _(optional)_
§
**Timezone:**
§
**Notes:**
§
Context: _(What do they care about? What projects are they working on? What annoys them? What makes them laugh? Build this over time.)_
§
Context: ---
§
Context: The more you know, the better you can help. But remember — you're learning about a person, not building a dossier. Respect the difference.
§
**工作流程偏好：** 所有新项目默认采用"完全隔离方案" —— 先创建独立项目环境（目录、虚拟环境、文档），然后使用子代理（delegate_task）进行开发，避免数据污染。不同项目之间保持严格隔离。
§
**称呼偏好：** 用户称这个"本地项目管理中心"对话框为 **「大管家」**。当用户叫"大管家"时，表示要进行本地所有项目的管理、运维、协调工作（不是单一项目开发）。这是用户的总控台/项目管家角色。
§
**工作流程偏好：** 多项目管理 —— 每个项目独立对话线程，用户用「称呼」标识项目（如「小厨」= CLM 项目）。新对话时如上下文模糊应主动询问「现在是哪个项目」。
§
🔑 用户期望与行为偏好
1. **自主操作优先**：用户会给权限让AI自主操作（如打开Docker Desktop），不要只给指令让用户手动执行
2. **持续交付期望**：用户期望AI能持续工作、自动推进，不喜欢被动等待
3. **文档驱动治理**：用户认可三层→五层治理架构（Memory + MemPalace + Obsidian + docs/ + graphify），要求所有关键信息持久化到工程目录
4. **本地优先开发**：云部署暂缓，先在本地完整验证后再考虑上传服务器
5. **工具融合偏好**：用户主动要求融合 MemPalace、Obsidian、graphify 到治理体系，不喜欢孤立工具

📁 CLM 项目关键路径
- 新工程：/Users/mac/Projects/clm-tools-kw/
- DateUse 源码：/Users/mac/software project/DateUse/
- 旧 CLM-Tools：~/software project/cursor/CLM-Tools/dailyReport/clm-review-tool/
- Obsidian Vault：~/Documents/CLM-Obsidian/
- Git 远程：git@github.com:gaogoying-sudo/clm-tools-kw.git（注意：URL曾被污染，已修复）