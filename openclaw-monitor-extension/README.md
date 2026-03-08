# Sessions Monitor - OpenClaw 会话监控面板

一个通用的 Chrome 扩展，用于在 OpenClaw 页面上显示 Agent 和 Session 状态监控。

## 功能特性

- 📊 **实时监控** - 显示所有 Agent 的状态、模型、Tokens 使用情况
- 🔄 **自动刷新** - 每 10 秒自动更新数据
- 🎨 **可自定义 UI** - 支持拖拽调整大小、展开/收起详情
- 🔒 **安全可靠** - 无 XSS 漏洞，内存泄漏已修复
- 🌍 **通用设计** - 支持任意 OpenClaw 实例，无硬编码配置

## 安装步骤

### 1. 克隆仓库

```bash
git clone https://github.com/jicaiji1-max/workspace-programmer.git
cd workspace-programmer/openclaw-monitor-extension
```

### 2. 启动 API 服务

```bash
node openclaw-sessions-api.js
```

服务默认运行在 `http://127.0.0.1:18790`

### 3. 加载 Chrome 扩展

1. 打开 Chrome 浏览器
2. 访问 `chrome://extensions/`
3. 开启右上角的 **开发者模式**
4. 点击 **加载已解压的扩展程序**
5. 选择 `openclaw-monitor-extension` 文件夹

### 4. 访问 OpenClaw

访问 `http://127.0.0.1:18789`，监控面板会自动显示在页面右上角。

## 使用说明

### 面板交互

- **点击卡片头部** - 展开/收起 Agent 详情
- **点击会话数量** - 展开/收起会话列表
- **拖拽头部** - 移动面板位置
- **拖拽右下角** - 调整面板大小
- **刷新按钮** - 手动刷新数据

### 显示内容

每个 Agent 卡片显示：
- Agent ID 和中文名字（可选）
- 当前使用的模型
- 运行状态（运行中/空闲/aborted）
- 累计 Tokens / Context Window
- Context 使用率（带进度条）
- 会话数量

## 项目结构

```
openclaw-monitor-extension/
├── manifest.json          # Chrome 扩展配置
├── content.js             # 核心注入脚本
├── openclaw-sessions-api.js  # 轻量级 API 服务
└── README.md              # 本文档
```

## 配置

### 自定义 Agent 中文名字

编辑 `openclaw-sessions-api.js` 中的 `AGENT_CN_NAMES` 对象：

```javascript
const AGENT_CN_NAMES = {
  'main': '主助手',
  'programmer': '代码助手',
  'product-manager': '产品助手',
  'project-manager': '项目经理'
};
```

### 从 SOUL.md 自动读取

API 服务会自动从 `SOUL.md` 文件标题提取当前 Agent 的中文名字：

```markdown
# SOUL.md - 代码助手
```

## 技术栈

- **前端**: Vanilla JavaScript (ES5), 无框架依赖
- **后端**: Node.js HTTP 服务
- **样式**: 内嵌 CSS，支持动态主题

## 安全说明

- ✅ 无 XSS 漏洞（使用 `createElement` 而非 `innerHTML`）
- ✅ 无内存泄漏（事件监听器自动清理）
- ✅ 本地运行（仅监听 `127.0.0.1`）
- ✅ 无外部依赖

## Code Review 状态

已通过完整 Code Review，所有高优先级问题已修复：

- [x] 代码重复严重 → 重构为模块化函数
- [x] 内存泄漏风险 → 添加事件监听器清理
- [x] 错误处理薄弱 → 完善 HTTP/JSON 错误处理
- [x] 边界情况处理 → 添加空值检查和默认值
- [x] XSS 安全漏洞 → 使用 `createElement` 避免 `innerHTML`

## 开发

### 调试

打开 Chrome 开发者工具（F12），查看 Console 日志：
- `[Monitor]` - 前端日志
- `[Sessions API]` - 后端 API 日志

### 修改后重新加载

1. 修改代码后保存
2. 在 `chrome://extensions/` 找到扩展
3. 点击刷新按钮 🔄
4. 刷新 OpenClaw 页面

## License

MIT

## 贡献

欢迎提交 Issue 和 Pull Request！

---

**维护者**: 菜🐒 @jicaiji1-max
**版本**: 1.0.4
**最后更新**: 2026-03-08
