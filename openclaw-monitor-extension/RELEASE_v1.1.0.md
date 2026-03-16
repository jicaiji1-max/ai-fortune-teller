# OpenClaw Monitor Extension v1.1.0 发布说明

**发布日期：** 2026-03-09  
**版本：** 1.1.0  
**上一版本：** 1.0.7

---

## 🎯 本次更新重点

### 1. 修复 5 个严重 Bug
### 2. 添加完整测试套件（75+ 测试用例）
### 3. 实现开机自动启动

---

## 🐛 Bug 修复详情

### Bug #1: 右下角拖拽调整大小完全失效 ⚠️ **严重**

**影响：** 用户无法通过拖拽右下角调整面板大小

**根本原因：**
```javascript
// content.js L821
var newWidth = (parseFloat(panel.style.width) || rect.width) + deltaX;
//                                                ^^^^^^^^^
// rect 变量在此处未定义（在另一个闭包中定义）
```

**修复方案：**
```javascript
// 在 mousemove handler 内获取 rect
var rect = panel.getBoundingClientRect();
var newWidth = (parseFloat(panel.style.width) || rect.width) + deltaX;
```

**测试验证：** ✅ `content.test.js` - Bug Fixes Verification

---

### Bug #2: 中文名字配置被默认值覆盖 ⚠️ **中等**

**影响：** 用户在 SOUL.md 中自定义的中文名字被忽略

**根本原因：**
```javascript
// openclaw-sessions-api.js L39-40
Object.assign(cnNames, defaultMappings);
// ❌ 错误：defaultMappings 覆盖了 cnNames 中已存在的值
```

**修复方案：**
```javascript
// 先设置默认值，再用 SOUL.md 的值覆盖
const finalNames = Object.assign({}, defaultMappings, cnNames);
```

**测试验证：** ✅ `integration.test.js` - Bug Fix Verification

---

### Bug #3: 内存泄漏 ⚠️ **严重**

**影响：** 长时间运行导致内存占用持续增长

**根本原因：**
```javascript
// content.js L84-93
function cleanupEventListeners() { /* ... */ }
// ❌ 定义了但从未被调用，导致 eventListeners 数组无限增长
```

**修复方案：**
```javascript
// 在页面卸载时清理
window.addEventListener('beforeunload', function() {
  cleanupEventListeners();
});
```

**测试验证：** ✅ `content.test.js` - Bug Fixes Verification

---

### Bug #4: API 请求无超时控制 ⚠️ **中等**

**影响：** API 服务异常时导致页面卡死

**根本原因：**
```javascript
// content.js L113
fetch(API_URL, { method: 'GET' })
// ❌ 无超时控制，API 挂起时永久等待
```

**修复方案：**
```javascript
// 使用 AbortController 添加 5 秒超时
var controller = new AbortController();
var timeoutId = setTimeout(() => controller.abort(), 5000);
fetch(API_URL, { signal: controller.signal })
  .finally(() => clearTimeout(timeoutId));
```

**测试验证：** ✅ `content.test.js` - Bug Fixes Verification

---

### Bug #5: 端口冲突时崩溃无提示 ⚠️ **低**

**影响：** API 服务启动失败时无友好提示

**根本原因：**
```javascript
// openclaw-sessions-api.js L142
server.listen(PORT, '127.0.0.1', () => { /* ... */ });
// ❌ 缺少 error 事件监听，端口冲突时进程直接崩溃
```

**修复方案：**
```javascript
server.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    console.error(`❌ 端口 ${PORT} 已被占用`);
    process.exit(1);
  }
});
```

**测试验证：** ✅ `integration.test.js` - Bug Fix Verification

---

## ✨ 新功能

### 1. 完整测试套件

#### 测试文件结构
```
tests/
├── README.md               # 测试文档
├── api.test.js             # API 服务器测试（25+ 用例）
├── content.test.js         # 前端函数测试（35+ 用例）
└── integration.test.js     # 端到端测试（15+ 用例）
```

#### 测试覆盖范围
- ✅ HTTP 端点测试
- ✅ CORS 头部测试
- ✅ Session 过滤测试
- ✅ 错误处理测试
- ✅ 中文名字映射测试
- ✅ 工具函数测试
- ✅ 性能测试（响应时间 < 100ms）
- ✅ 并发请求测试
- ✅ 压力测试（20+ 并发）

#### 运行测试
```bash
npm install          # 安装依赖
npm test             # 运行所有测试
npm run test:coverage  # 生成覆盖率报告
```

---

### 2. 开机自动启动

**问题：** 重启电脑后 API 服务需要手动启动，导致 Chrome 扩展报错

**解决方案：**
1. **启动脚本：** `start-api.sh`
   - 检查是否已运行
   - 启动 Node.js 服务
   - 记录 PID 到文件

2. **LaunchAgent：** `~/Library/LaunchAgents/ai.openclaw.monitor-api.plist`
   - 开机自动加载
   - 日志记录
   - 优雅退出

**使用方法：**
```bash
# 手动启动
./start-api.sh

# 查看日志
tail -f /tmp/openclaw-monitor-api.log

# 卸载自动启动
launchctl unload ~/Library/LaunchAgents/ai.openclaw.monitor-api.plist
```

---

### 3. NPM 脚本支持

**新增命令：**
```bash
npm run start-api        # 启动 API 服务
npm test                 # 运行所有测试
npm run test:watch       # 监听模式（自动重新运行）
npm run test:coverage    # 生成覆盖率报告
```

---

## 📊 统计数据

| 指标 | 数值 | 变化 |
|------|------|------|
| 总代码行数 | ~1,300 行 | +100 行 |
| Bug 修复数 | 5 个 | 🆕 |
| 测试用例数 | 75+ | 🆕 |
| 代码覆盖率 | 80%+ | 🆕 |
| 新增文件数 | 6 个 | 🆕 |

---

## 🎁 升级方法

### 方式 1：Git 拉取（推荐）
```bash
cd ~/.openclaw/workspace-programmer/openclaw-monitor-extension
git pull origin main
```

### 方式 2：重新克隆
```bash
cd ~/.openclaw/workspace-programmer
rm -rf openclaw-monitor-extension
git clone https://github.com/jicaiji1-max/openclaw-monitor-extension.git
```

### 方式 3：手动替换
下载 ZIP，替换文件。

---

## ✅ 升级后检查清单

- [ ] `npm install` 安装测试依赖
- [ ] `npm test` 运行测试，确保所有测试通过
- [ ] `./start-api.sh` 启动 API 服务
- [ ] 打开 Chrome 扩展，验证监控面板正常显示
- [ ] 测试拖拽调整大小功能
- [ ] 重启电脑，验证 API 服务自动启动

---

## 🚀 下一版本计划 (v1.2.0)

- [ ] 添加更多性能监控指标
- [ ] 支持自定义刷新间隔
- [ ] 添加导出数据功能
- [ ] 优化大量 sessions 场景下的性能
- [ ] 支持主题切换

---

## 💬 反馈与建议

如有问题或建议，请提交 Issue 或 PR：  
https://github.com/jicaiji1-max/openclaw-monitor-extension

---

**感谢使用 OpenClaw Monitor Extension！** 🎉
