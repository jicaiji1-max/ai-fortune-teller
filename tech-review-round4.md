# 第 4 轮技术评审：功能细节确认

## 评审时间
2026-03-06 11:45

## 参与人员
- 🐒 代码助手（技术评审）
- 🐶 产品小助手（产品分析）

## 数据模型设计

### 核心数据结构（TypeScript）

```typescript
// 主数据结构 - 存储于 localStorage
interface AppData {
  transactions: Transaction[];      // 交易记录
  accounts: Account[];              // 账户
  categories: Category[];           // 分类
  settings: Settings;               // 设置
  meta: Meta;                       // 元数据
}

// 交易记录
interface Transaction {
  id: string;                       // UUID v4
  type: 'income' | 'expense';       // 类型
  amount: number;                   // 金额（单位：分，避免浮点误差）
  categoryId: string;               // 分类 ID
  accountId: string;                // 账户 ID
  date: string;                     // ISO 日期字符串 YYYY-MM-DD
  note: string;                     // 备注（max 200 字）
  createdAt: number;                // 创建时间戳（ms）
  updatedAt: number;                // 更新时间戳（ms）
}

// 账户
interface Account {
  id: string;                       // UUID v4
  name: string;                     // 账户名（max 50 字）
  type: 'cash' | 'bank' | 'card';   // 类型
  balance: number;                  // 余额（单位：分）
  icon: string;                     // emoji 图标
  createdAt: number;                // 创建时间戳
}

// 分类
interface Category {
  id: string;                       // UUID v4
  type: 'income' | 'expense';       // 类型
  name: string;                     // 分类名（max 20 字）
  icon: string;                     // emoji 图标
  parentId?: string;                // 父分类 ID（支持二级分类）
  isDefault: boolean;               // 是否预置分类（不可删除）
  order: number;                    // 排序序号
}

// 设置
interface Settings {
  currency: string;                 // 货币符号（默认：¥）
  firstDayOfWeek: number;           // 周起始日（0=周日，1=周一）
  exportReminder: boolean;          // 是否开启导出提醒
  lastExportDate?: string;          // 上次导出日期
  theme: 'light' | 'dark';          // 主题
}

// 元数据
interface Meta {
  version: string;                  // 数据结构版本
  lastBackup?: string;              // 上次备份日期
  createdAt: number;                // 应用创建时间
}
```

### localStorage Key 设计

```
记账应用 - 主数据：bookkeeping_app_data
记账应用 - 索引：bookkeeping_app_index
```

## API 接口设计（前端服务层）

### 交易服务 TransactionService

```typescript
interface TransactionService {
  // 查询列表（支持筛选、分页、排序）
  list(filters: {
    type?: 'income' | 'expense';
    categoryId?: string;
    accountId?: string;
    dateFrom?: string;
    dateTo?: string;
    page?: number;
    pageSize?: number;
    sortBy?: 'date' | 'amount' | 'createdAt';
    sortOrder?: 'asc' | 'desc';
  }): { data: Transaction[]; total: number };
  
  // 获取单笔
  getById(id: string): Transaction | null;
  
  // 创建
  create(data: {
    type: 'income' | 'expense';
    amount: number;
    categoryId: string;
    accountId: string;
    date: string;
    note?: string;
  }): Transaction;
  
  // 更新
  update(id: string, data: Partial<Transaction>): Transaction;
  
  // 删除
  delete(id: string): boolean;
  
  // 删除批量
  deleteBatch(ids: string[]): number;
  
  // 获取月度统计
  getMonthlyStats(year: number, month: number): {
    income: number;
    expense: number;
    balance: number;
    byCategory: Array<{ categoryId: string; amount: number }>;
  };
}
```

### 账户服务 AccountService

```typescript
interface AccountService {
  list(): Account[];
  getById(id: string): Account | null;
  create(data: { name: string; type: string; icon: string; initialBalance?: number }): Account;
  update(id: string, data: Partial<Account>): Account;
  delete(id: string): boolean;
  getTotalBalance(): number;
  getBalanceByType(type: string): number;
}
```

### 分类服务 CategoryService

```typescript
interface CategoryService {
  list(type?: 'income' | 'expense'): Category[];
  getDefaults(type: 'income' | 'expense'): Category[];
  create(data: { type: string; name: string; icon: string; parentId?: string }): Category;
  update(id: string, data: Partial<Category>): Category;
  delete(id: string): boolean;
}
```

### 导出服务 ExportService

```typescript
interface ExportService {
  toCSV(transactions: Transaction[]): string;
  downloadCSV(filename?: string): void;
  toJSON(): string;
  downloadJSON(filename?: string): void;
  importJSON(data: string): { success: boolean; count: number; error?: string };
}
```

## 技术实现方案

### 1. 项目结构

```
src/
├── components/           # UI 组件
│   ├── Dashboard/
│   ├── Transaction/
│   ├── Account/
│   ├── Category/
│   └── common/
├── services/             # 业务服务层
│   ├── transaction.ts
│   ├── account.ts
│   ├── category.ts
│   └── export.ts
├── repositories/         # 数据访问层
│   └── localStorage.ts
├── stores/               # 状态管理（Zustand）
│   ├── appStore.ts
│   └── uiStore.ts
├── hooks/                # 自定义 Hooks
├── utils/                # 工具函数
└── types/                # TypeScript 类型定义
```

### 2. 技术选型确认

| 类别 | 技术 | 理由 |
|------|------|------|
| 框架 | React 18 | 最新稳定版，Concurrent 特性 |
| 语言 | TypeScript 5 | 类型安全，开发体验好 |
| 状态 | Zustand | 轻量（<1KB），API 简单 |
| 表单 | React Hook Form | 性能好，类型友好 |
| UI 库 | shadcn/ui | 基于 Tailwind，可定制 |
| 图表 | Recharts | 轻量，React 友好 |
| 日期 | date-fns | 轻量，Tree-shaking |
| UUID | uuid | 标准库 |
| CSV | PapaParse | 成熟稳定 |
| 构建 | Vite | 快速，HMR 体验好 |

### 3. 开发规范

- ESLint + Prettier 代码规范
- Commit message: Conventional Commits
- 分支策略：main + feature 分支
- 代码审查：必须经过 review 才能合并

## 技术风险评估

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| localStorage 容量限制 | 低 | 中 | 限制单条备注长度，定期清理 |
| 数据丢失 | 中 | 高 | 导出功能 + 备份提醒 |
| 性能问题（大数据量） | 中 | 中 | 虚拟列表 + 分页 |
| 浏览器兼容性 | 低 | 中 | 检测 + 降级提示 |

## 下一步
进入第 5 轮：最终 PRD 确认（技术评审签字）
