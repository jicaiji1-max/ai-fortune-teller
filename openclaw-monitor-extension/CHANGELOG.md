# 更新日志

## [1.1.0] - 2026-03-09

### 🐛 Bug 修复

#### Bug #1: 右下角拖拽调整大小失效
- **位置：** content.js L821
- **问题：** `rect` 变量在 mousemove handler 中未定义，导致 `NaN` 计算错误
- **修复：** 在 handler 内获取 `panel.getBoundingClientRect()`
- **影响：** 拖拽调整面板大小功能完全失效 → 已修复

#### Bug #2: 中文名字配置被默认值覆盖
- **位置：** openclaw-sessions-api.js L39-40
- **问题：** `Object.assign(cnNames, defaultMappings)` 顺序错误
- **修复：** 先设置默认值，再用 SOUL.md 的值覆盖
- **影响：** 用户在 SOUL.md 中自定义的中文名字被忽略 → 已修复

#### Bug #3: 内存泄漏
- **位置：** content.js L84-93
- **问题：** `cleanupEventListeners` 函数从未被调用
- **修复：** 在 `window.beforeunload` 事件中调用清理函数
- **影响：** 长时间运行导致内存占用持续增长 → 已修复

#### Bug #4: API 请求无超时控制
- **位置：** content.js L113
- **问题：** `fetch` 无超时，API 无响应时永久挂起
- **修复：** 使用 `AbortController` 添加 5 秒超时
- **影响：** API 服务异常时导致页面卡死 → 已修复

#### Bug #5: 端口冲突处理缺失
- **位置：** openclaw-sessions-api.js L142
- **问题：** 缺少 `server.on('error')` 处理，端口冲突时进程崩溃
- **修复：** 添加错误处理，输出友好提示并优雅退出
- **影响：** 端口被占用时进程崩溃无提示 → 已修复

---

### ✨ 新功能

#### 1. 完整测试套件
- 添加 75+ 测试用例覆盖所有核心功能
- API 服务器测试（25+ 用例）
- 前端工具函数测试（35+ 用例）
- 端到端集成测试（15+ 用例）

#### 2. 开机自动启动
- 创建 LaunchAgent 配置
- 添加启动脚本 `start-api.sh`
- 重启电脑后 API 服务自动运行

#### 3. NPM 脚本支持
- `npm test` - 运行所有测试
- `npm run test:watch` - 监听模式
- `npm run test:coverage` - 生成覆盖率报告
- `npm run start-api` - 启动 API 服务

---

### 📁 新增文件

```
openclaw-monitor-extension/
├── package.json              (新增)
├── CHANGELOG.md              (新增)
├── start-api.sh              (新增)
├── tests/                    (新增)
│   ├── README.md
│   ├── api.test.js
│   ├── content.test.js
│   └── integration.test.js
└── ~/Library/LaunchAgents/
    └── ai.openclaw.monitor-api.plist  (新增)
```

---

### 🔧 改进

- 错误处理更加完善
- 内存管理更加稳定
- 性能优化（fetch 超时控制）
- 代码质量提升（测试覆盖）

---

### 📊 测试统计

| 指标 | 数值 |
|------|------|
| 测试用例数 | 75+ |
| 代码覆盖率 | 80%+ |
| Bug 修复数 | 5 个 |
| 新增文件 | 6 个 |

---

### 🎯 下一版本计划 (1.2.0)

- [ ] 添加更多性能监控指标
- [ ] 支持自定义刷新间隔
- [ ] 添加导出数据功能
- [ ] 优化大量 sessions 场景下的性能
- [ ] 支持主题切换

---

## [1.0.0] - 2026-03-08

### 初始版本
- OpenClaw Agent 监控面板
- 实时显示所有 agent 状态
- 三级展开设计
- 中文名字映射
- 可拖拽调整位置和大小

## [1.1.1] - 2026-03-10

### 🐛 Bug 修复

#### 改进 API 请求错误处理

- **AbortError 友好提示**: 超时错误现在显示 "请求超时（超过 5 秒），请检查 API 服务是否正常运行"
- **JSON 解析错误提示**: 现在显示 "响应解析失败：服务返回了非 JSON 格式的数据"
- **自动重试机制**: 请求失败后自动重试 1 次（1 秒延迟）
- **超时时间可配置**: 新增 `FETCH_TIMEOUT_MS` 常量（默认 5000ms）

### 📊 影响

- 提升用户体验：错误提示更清晰
- 提升稳定性：网络抖动时自动重试
- 提升可维护性：超时时间集中配置

