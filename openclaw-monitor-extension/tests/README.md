# OpenClaw Monitor Extension - 测试文档

## 🧪 测试概览

本项目包含三类测试：

| 测试文件 | 测试内容 | 测试数量 |
|---------|---------|---------|
| `api.test.js` | API 服务器功能测试 | ~25 个 |
| `content.test.js` | 前端工具函数测试 | ~35 个 |
| `integration.test.js` | 端到端集成测试 | ~15 个 |

**总计：** ~75 个测试用例

---

## 📦 安装依赖

```bash
cd ~/.openclaw/workspace-programmer/openclaw-monitor-extension
npm install
```

---

## 🚀 运行测试

### 运行所有测试
```bash
npm test
```

### 运行指定测试文件
```bash
npm test api.test.js
npm test content.test.js
npm test integration.test.js
```

### 监听模式（自动重新运行）
```bash
npm run test:watch
```

### 生成覆盖率报告
```bash
npm run test:coverage
```

---

## 🐛 测试覆盖的 Bug

### Bug #1: content.js L821 - 拖拽调整大小失效
**问题：** `rect` 变量未定义  
**修复：** 在 mousemove handler 内获取 `rect`  
**测试：** `content.test.js` - Bug Fixes Verification

### Bug #2: openclaw-sessions-api.js L39-40 - 中文名字被覆盖
**问题：** `Object.assign(cnNames, defaultMappings)` 顺序错误  
**修复：** 先设置默认值，再用 SOUL.md 覆盖  
**测试：** `integration.test.js` - Bug Fix Verification

### Bug #3: content.js - 内存泄漏
**问题：** `cleanupEventListeners` 从未被调用  
**修复：** 在 `beforeunload` 事件中调用  
**测试：** `content.test.js` - Bug Fixes Verification

### Bug #4: content.js L113 - 无超时控制
**问题：** `fetch` 无超时，API 挂起时永久等待  
**修复：** 使用 `AbortController` 添加 5 秒超时  
**测试：** `content.test.js` - Bug Fixes Verification

### Bug #5: openclaw-sessions-api.js L142 - 缺少错误处理
**问题：** 端口冲突时进程崩溃无提示  
**修复：** 添加 `server.on('error')` 处理  
**测试：** `integration.test.js` - Bug Fix Verification

---

## 📊 测试覆盖范围

### API Server (api.test.js)
- ✅ HTTP 端点测试
- ✅ CORS 头部测试
- ✅ Session 过滤测试
- ✅ 错误处理测试
- ✅ 中文名字映射测试

### Content Script (content.test.js)
- ✅ formatTokens 格式化测试
- ✅ getContextPercent 百分比计算
- ✅ getContextLevel 等级判断
- ✅ getSessionStatus 状态判断
- ✅ Bug 修复验证

### Integration (integration.test.js)
- ✅ API 可用性测试
- ✅ 数据格式验证
- ✅ 性能测试（响应时间 < 100ms）
- ✅ 并发请求测试
- ✅ 压力测试（20+ 并发）

---

## 🎯 测试前提条件

### 1. API 服务器必须运行
```bash
npm run start-api
# 或
node openclaw-sessions-api.js
```

### 2. OpenClaw 实例应该运行
API 测试需要访问 `~/.openclaw/agents/*/sessions/sessions.json`

---

## 📈 CI/CD 集成

### GitHub Actions 示例
```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm install
      - run: npm run start-api &
      - run: sleep 2
      - run: npm test
```

---

## 🔍 调试测试

### 启用详细输出
```bash
npm test -- --verbose
```

### 只运行匹配的测试
```bash
npm test -- --testNamePattern="formatTokens"
```

### 查看覆盖率详情
```bash
npm run test:coverage
open coverage/lcov-report/index.html
```

---

## 📝 添加新测试

1. 在 `tests/` 目录创建新测试文件
2. 使用 Jest 语法：`describe`, `test`, `expect`
3. 运行 `npm test` 验证

示例：
```javascript
describe('New Feature', () => {
  test('should work correctly', () => {
    expect(1 + 1).toBe(2);
  });
});
```

---

## 🎉 测试通过标准

- ✅ 所有测试通过
- ✅ 代码覆盖率 > 80%
- ✅ 无 console.error 输出
- ✅ 性能测试在限定时间内完成
