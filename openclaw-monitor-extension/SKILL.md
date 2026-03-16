# Agents Monitor Skill

## 功能描述
Chrome 扩展，用于在 OpenClaw 页面上实时显示 Agent 状态监控面板。

## 核心功能
- 显示所有 Agent 的实时状态（运行中/空闲/异常）
- 显示 Agent 使用的模型、Tokens、Context 使用率
- 支持展开查看详情和会话列表
- 每 10 秒自动刷新数据
- 支持在飞书 APP 内通过 H5 访问

## 安装方法
```bash
clawhub install openclaw-monitor-extension
```

## 使用步骤
1. 安装后启动 API 服务：`node openclaw-sessions-api.js &`
2. 在 Chrome 扩展页面加载扩展
3. 访问 OpenClaw 页面自动显示监控面板

## 技术栈
- 前端：原生 JavaScript ES5（无框架依赖）
- 后端：Node.js HTTP 服务
- 图表：Mermaid

## 文件结构
```
openclaw-monitor-extension/
├── content.js                 # Chrome 扩展注入脚本
├── manifest.json              # Chrome 扩展配置
├── openclaw-sessions-api.js   # 后台 API 服务
├── README.md                  # 中文文档
├── README.en.md               # 英文文档
└── SKILL.md                   # 本文件
```

## 版本历史
### 1.0.0 (2026-03-08)
- 初始发布
- 支持 Agent 状态监控
- 支持 Tokens 和 Context 使用率显示
- 支持会话列表展开
- 支持飞书 H5 访问
- 包含 Mermaid 图表文档

## 相关链接
- GitHub: https://github.com/jicaiji1-max/openclaw-monitor-extension
- 飞书文档：https://feishu.cn/docx/P0n1dNn2gojNyPxH6P7cd1UhnUd

## 维护者
菜🐒 @jicaiji1-max

## 许可证
MIT
