# 🐒 网页版记账本 - 技术评审报告

**评审人:** 菜🐒 (代码助手)  
**评审日期:** 2026-03-06  
**评审状态:** 🟡 等待产品小助手提供完整 PRD 内容  
**PRD 文档:** https://mcnu6fdpos6q.feishu.cn/docx/FvscdXlCyo7kNMxmX2Nc7136n7g

---

## 执行摘要

**技术可行性结论:** ✅ 整体可行，技术栈匹配度高

**开发周期评估:** 🟡 23 天基本合理，但需确认 MVP 范围

**主要风险:** 需求范围不明确、可能的需求变更

**建议:** 优先冻结 MVP 功能范围，采用迭代开发模式

---

## 一、技术可行性分析

### 1.1 P0 功能 (MVP) 评估

> **注:** 以下基于通用记账本应用功能推测，待 PRD 确认后更新

| 功能模块 | 技术可行性 | 难度评估 | 工时估算 | 备注 |
|---------|-----------|---------|---------|------|
| 用户注册/登录 | ✅ 可行 | 低 | 0.5 天 | JWT + bcrypt, 含邮箱验证 |
| 记账功能 (增删改查) | ✅ 可行 | 低 | 2 天 | CRUD 基础功能 |
| 账单分类管理 | ✅ 可行 | 低 | 1 天 | 单表关联，支持自定义 |
| 数据统计展示 | ✅ 可行 | 中 | 2 天 | 需要聚合查询，图表展示 |
| 预算设置 | ✅ 可行 | 低 | 1 天 | 简单配置，阈值提醒 |
| 数据导出 (CSV/Excel) | ✅ 可行 | 低 | 0.5 天 | 使用 csv-writer / xlsx 库 |

**P0 功能总计:** 约 7 天开发时间 (不含测试)

### 1.2 技术栈匹配度

**拟定技术栈:** React + NestJS + PostgreSQL

| 技术 | 匹配度 | 说明 |
|-----|-------|------|
| React (前端) | ✅ 完全匹配 | 适合 SPA 应用，组件化开发 |
| NestJS (后端) | ✅ 完全匹配 | TypeScript 全栈，模块化架构 |
| PostgreSQL (数据库) | ✅ 完全匹配 | 关系型数据，支持复杂查询 |

**推荐补充的技术栈:**

| 类别 | 推荐方案 | 说明 |
|-----|---------|------|
| 状态管理 | Zustand | 轻量级，适合中小型应用 |
| UI 组件库 | Ant Design | 企业级组件，文档完善 |
| 图表库 | Recharts | React 友好，配置灵活 |
| 表单验证 | React Hook Form + Zod | 类型安全，性能好 |
| HTTP 客户端 | Axios / TanStack Query | 请求管理 + 缓存 |
| 日期处理 | dayjs | 轻量级日期库 |
| CSS 方案 | Tailwind CSS | 原子化 CSS，开发效率高 |

---

## 二、开发周期评估

### 2.1 23 天开发计划分析

**当前评估:** 🟡 23 天基本合理，但需确认 MVP 范围

**详细时间分配建议:**

| 阶段 | 天数 | 主要任务 | 交付物 |
|-----|------|---------|-------|
| 需求确认 + 技术设计 | 2 天 | 接口设计、数据库设计、原型确认 | API 文档、ER 图 |
| 前端基础框架 | 2 天 | 项目搭建、组件库集成、路由配置 | 前端脚手架 |
| 后端基础框架 | 2 天 | 项目搭建、认证系统、数据库连接 | 后端脚手架 |
| 用户模块 | 1 天 | 注册、登录、个人信息 | 用户 CRUD |
| 记账核心功能 | 3 天 | 账单增删改查、分类管理 | 账单 CRUD |
| 数据统计 | 2 天 | 收支统计、图表展示 | 统计页面 |
| 预算功能 | 1 天 | 预算设置、超支提醒 | 预算模块 |
| 数据导出 | 0.5 天 | CSV/Excel 导出 | 导出功能 |
| 联调测试 | 3 天 | 前后端联调、Bug 修复 | 测试报告 |
| 部署上线 | 2 天 | 服务器配置、CI/CD、域名配置 | 生产环境 |
| 缓冲时间 | 4.5 天 | 需求变更、意外问题 | - |
| **总计** | **23 天** | | |

### 2.2 风险点识别

**可能延期的任务:**

| 风险任务 | 风险等级 | 原因 | 缓解措施 |
|---------|---------|------|---------|
| 数据统计功能 | 🟡 中 | 复杂度取决于需求 | 先实现基础统计，高级图表迭代 |
| 第三方集成 | 🟡 中 | API 对接不确定性 | 明确集成范围，预留缓冲时间 |
| 移动端适配 | 🟡 中 | 如需要响应式 | 使用响应式框架，优先桌面端 |
| 需求变更 | 🔴 高 | 开发过程中新增需求 | 冻结 MVP 范围，变更走迭代 |

---

## 三、技术风险清单

| 风险项 | 等级 | 影响 | 应对方案 | 负责人 |
|-------|------|------|---------|-------|
| 需求变更 | 🔴 高 | 延期 | 冻结 MVP 范围，新增需求走迭代 | 产品 + 技术 |
| 数据量增长 | 🟢 低 | 性能下降 | 设计时考虑索引和分页，定期归档 | 技术 |
| 安全性 | 🟡 中 | 数据泄露 | JWT 认证、输入验证、SQL 防注入、HTTPS | 技术 |
| 性能问题 | 🟢 低 | 用户体验差 | 初期用户量少，后期优化 + 缓存 | 技术 |
| 第三方依赖 | 🟡 中 | 功能受限 | 选择成熟稳定的库，准备备选方案 | 技术 |
| 部署问题 | 🟡 中 | 上线延期 | 提前准备部署脚本，CI/CD 自动化 | 技术 |

---

## 四、待确认项 (需要老板决策)

### 4.1 功能范围

| 序号 | 问题 | 选项 | 建议 | 优先级 |
|-----|------|------|------|-------|
| 1 | 是否需要移动端适配？ | A. 响应式网页 B. 独立 App C. 暂不需要 | A. 响应式网页 | P0 |
| 2 | 是否需要数据导出功能？ | A. CSV B. Excel C. 都不需要 | A. CSV (简单) | P1 |
| 3 | 是否需要多币种支持？ | A. 需要 B. 暂不需要 | B. 暂不需要 | P2 |
| 4 | 是否需要团队协作功能？ | A. 共享账本 B. 单人使用 | B. 单人使用 (MVP) | P2 |
| 5 | 是否需要数据导入功能？ | A. Excel 导入 B. 其他平台导入 C. 不需要 | C. 不需要 (MVP) | P2 |

### 4.2 技术选型

| 序号 | 问题 | 选项 | 建议 | 说明 |
|-----|------|------|------|------|
| 1 | 部署环境偏好？ | A. 云服务器 B. Vercel + Supabase C. 其他 | B. Vercel + Supabase | 成本低，运维简单 |
| 2 | 是否需要用户邮箱验证？ | A. 需要 B. 不需要 | A. 需要 | 提高账号安全性 |
| 3 | 是否需要第三方登录？ | A. 微信 B. 谷歌 C. 不需要 | C. 不需要 (MVP) | 减少初期复杂度 |

### 4.3 开发资源

| 序号 | 问题 | 选项 | 建议 |
|-----|------|------|------|
| 1 | 开发人员配置？ | A. 1 全栈 B. 1 前端 +1 后端 | A. 1 全栈 (MVP) |
| 2 | 是否需要 UI 设计？ | A. 专业设计 B. 使用组件库 | B. 使用组件库 |

---

## 五、MVP 范围建议 (前 13 天优先)

### 5.1 前 13 天优先完成 (P0)

| 优先级 | 功能模块 | 工时 | 说明 |
|-------|---------|------|------|
| P0 | 用户注册/登录 | 0.5 天 | 含邮箱验证 |
| P0 | 账单增删改查 | 2 天 | 核心功能 |
| P0 | 分类管理 | 1 天 | 收入/支出分类 |
| P0 | 基础统计 | 1.5 天 | 收支汇总、简单图表 |
| P0 | 前端框架搭建 | 2 天 | 项目初始化、组件库 |
| P0 | 后端框架搭建 | 2 天 | 项目初始化、认证系统 |
| P0 | 数据库设计 | 1 天 | 表结构设计、索引 |
| P0 | 联调测试 | 3 天 | 前后端联调、Bug 修复 |
| P0 | 部署上线 | 2 天 | 生产环境配置 |
| **小计** | | **13 天** | |

### 5.2 后续迭代 (P1/P2)

| 优先级 | 功能模块 | 工时 | 说明 |
|-------|---------|------|------|
| P1 | 预算设置 | 1 天 | 预算配置、超支提醒 |
| P1 | 数据导出 | 0.5 天 | CSV 导出 |
| P1 | 高级统计 | 1.5 天 | 趋势图、分类占比 |
| P2 | 数据导入 | 1 天 | CSV/Excel 导入 |
| P2 | 多账本管理 | 2 天 | 多账本切换 |
| P2 | 第三方登录 | 1 天 | 微信/谷歌登录 |
| P2 | 移动端优化 | 2 天 | 响应式适配 |

---

## 六、下一步行动

### 6.1 立即行动 (今日完成)

- [ ] **产品小助手:** 更新 PRD 文档，明确 P0/P1/P2 功能列表
- [ ] **代码助手:** 完成技术评审报告初稿 ✅ (进行中)
- [ ] **老板:** 确认待确认项中的技术选型和功能范围

### 6.2 本周行动

- [ ] **产品 + 技术:** 确认最终 MVP 范围 (前 13 天功能)
- [ ] **代码助手:** 输出详细技术方案 (API 设计、数据库设计)
- [ ] **老板:** 确认开发资源 (1 全栈 or 1 前端 +1 后端)
- [ ] **产品 + 技术:** 确认 23 天开发计划

### 6.3 下周行动

- [ ] **代码助手:** 搭建前后端项目框架
- [ ] **代码助手:** 实现用户认证系统
- [ ] **产品:** 准备 UI 设计稿或使用组件库原型

---

## 七、附录

### 7.1 数据库设计草案

```sql
-- 用户表
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  nickname VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 分类表
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  name VARCHAR(100) NOT NULL,
  type VARCHAR(20) NOT NULL, -- 'income' or 'expense'
  icon VARCHAR(100),
  color VARCHAR(20),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 账单表
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  category_id UUID REFERENCES categories(id),
  amount DECIMAL(12, 2) NOT NULL,
  type VARCHAR(20) NOT NULL, -- 'income' or 'expense'
  description TEXT,
  transaction_date DATE NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 预算表
CREATE TABLE budgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  category_id UUID REFERENCES categories(id),
  amount DECIMAL(12, 2) NOT NULL,
  period VARCHAR(20) NOT NULL, -- 'monthly' or 'yearly'
  start_date DATE NOT NULL,
  end_date DATE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 索引
CREATE INDEX idx_transactions_user_date ON transactions(user_id, transaction_date);
CREATE INDEX idx_transactions_category ON transactions(category_id);
CREATE INDEX idx_categories_user ON categories(user_id);
```

### 7.2 API 设计草案

```
# 认证
POST /api/auth/register      # 用户注册
POST /api/auth/login         # 用户登录
POST /api/auth/logout        # 用户登出
GET  /api/auth/me            # 获取当前用户信息

# 用户
GET  /api/users/me           # 获取个人信息
PUT  /api/users/me           # 更新个人信息

# 分类
GET  /api/categories         # 获取分类列表
POST /api/categories         # 创建分类
PUT  /api/categories/:id     # 更新分类
DELETE /api/categories/:id   # 删除分类

# 账单
GET  /api/transactions       # 获取账单列表 (支持筛选、分页)
POST /api/transactions       # 创建账单
GET  /api/transactions/:id   # 获取账单详情
PUT  /api/transactions/:id   # 更新账单
DELETE /api/transactions/:id # 删除账单

# 统计
GET  /api/stats/summary      # 收支汇总
GET  /api/stats/trend        # 趋势图数据
GET  /api/stats/category     # 分类占比

# 预算
GET  /api/budgets            # 获取预算列表
POST /api/budgets            # 创建预算
PUT  /api/budgets/:id        # 更新预算
DELETE /api/budgets/:id      # 删除预算

# 导出
GET  /api/export/csv         # 导出 CSV
```

---

*最后更新：2026-03-06 11:00*  
*文档状态：🟡 待 PRD 确认后更新*
