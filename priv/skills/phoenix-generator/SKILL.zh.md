---
name: phoenix-generator
description: 使用 mix phx.gen.* 命令生成 Phoenix 资源（contexts、schemas、LiveViews、controllers），遵循最佳实践。在创建新的 Phoenix 资源、contexts 或 LiveView 组件时使用。
allowed-tools: Bash, Read, Edit, Write
---

# Phoenix Generator

此技能帮助使用内置生成器生成 Phoenix 资源，遵循适当的模式和最佳实践。

## 何时使用

- 创建新的 Phoenix contexts
- 向现有 contexts 添加 schemas
- 生成 LiveView CRUD 界面
- 创建 JSON/HTML 资源
- 搭建身份验证

## 可用的生成器

### Context 和 Schema 生成

**mix phx.gen.context** - 生成包含 schema 和迁移的 context
```bash
mix phx.gen.context Accounts User users name:string email:string:unique age:integer
```

生成：
- Context 模块：`lib/my_app/accounts.ex`
- Schema：`lib/my_app/accounts/user.ex`
- 迁移：`priv/repo/migrations/*_create_users.exs`
- 测试文件

**mix phx.gen.schema** - 仅生成 schema 和迁移（无 context）
```bash
mix phx.gen.schema Accounts.User users name:string email:string:unique
```

### LiveView 生成器

**mix phx.gen.live** - 完整的 LiveView CRUD 及 context
```bash
mix phx.gen.live Catalog Product products \
  name:string \
  description:text \
  price:decimal \
  sku:string:unique \
  in_stock:boolean
```

生成：
- Context 和 schema
- LiveView 模块（Index、Show、Form Component）
- 路由
- 测试

**mix phx.gen.live.component** - 独立的 LiveView 组件
```bash
mix phx.gen.live.component Components.Modal
```

### 传统 Web 生成器

**mix phx.gen.html** - 带有 controllers 的 HTML 资源
```bash
mix phx.gen.html Blog Post posts title:string body:text published:boolean
```

**mix phx.gen.json** - JSON API 资源
```bash
mix phx.gen.json Shop Product products name:string price:decimal
```

## 字段类型和修饰符

### 常见字段类型
- `string` - varchar(255)
- `text` - 无限制文本
- `integer` - 整数
- `decimal` - 精确小数（用于金钱）
- `float` - 浮点数
- `boolean` - 真/假
- `date` - 仅日期
- `time` - 仅时间
- `datetime` - 时间戳
- `uuid` - UUID
- `binary` - 二进制数据

### 字段修饰符
- `:unique` - 添加唯一索引
- `:redact` - 标记为在日志中进行编辑
- `name:string:unique:redact` - 链接修饰符

### 引用（关联）
```bash
# belongs_to
mix phx.gen.context Blog Post posts \
  title:string \
  body:text \
  user_id:references:users

# 指定自定义引用
mix phx.gen.context Comments Comment comments \
  body:text \
  post_id:references:posts \
  author_id:references:users
```

## 最佳实践

### 1. Context 命名
- Context 使用复数：`Accounts`、`Catalog`、`Blog`
- Schema 使用单数：`User`、`Product`、`Post`
- 表名与 schema 复数匹配：`users`、`products`、`posts`

### 2. 字段选择
```bash
# 好的做法：特定类型
price:decimal         # 用于金钱
published_at:datetime # 用于时间戳
active:boolean        # 用于标志

# 避免：错误的类型
price:float          # 金钱会丧失精度
published:string     # 使用 datetime 或 boolean
```

### 3. 关联
```bash
# 始终明确指定引用
user_id:references:users

# 不要对外键使用裸整数
user_id:integer  # 缺少关联元数据
```

### 4. 小数精度
对于金钱字段，更新迁移：
```elixir
# 生成的
add :price, :decimal

# 最佳实践 - 指定精度
add :price, :decimal, precision: 10, scale: 2
```

### 5. 字符串长度限制
更新 schema 以进行验证：
```elixir
# 添加到 changeset
|> validate_length(:name, max: 100)
|> validate_length(:email, max: 160)
```

## 生成器工作流

### 步骤 1：规划 Schema
```bash
# 列出字段及其类型
name:string
email:string:unique
age:integer
bio:text
admin:boolean
inserted_at:datetime
updated_at:datetime  # 自动使用 timestamps()
```

### 步骤 2：生成资源
```bash
# 选择适当的生成器
mix phx.gen.live Accounts User users \
  name:string \
  email:string:unique \
  age:integer \
  bio:text \
  admin:boolean
```

### 步骤 3：审查生成的文件
- 检查迁移是否有适当的索引和约束
- 审查 schema 以查看是否需要额外的验证
- 根据需要更新 context 函数
- 审查测试并添加边界情况

### 步骤 4：自定义迁移
```bash
# 运行迁移前，编辑它
vim priv/repo/migrations/*_create_users.exs
```

添加：
- 检查约束
- 默认值
- 额外索引
- 小数精度

### 步骤 5：添加路由（如需要）
```elixir
# lib/my_app_web/router.ex
scope "/", MyAppWeb do
  pipe_through :browser

  live "/users", UserLive.Index, :index
  live "/users/new", UserLive.Index, :new
  live "/users/:id/edit", UserLive.Index, :edit
  live "/users/:id", UserLive.Show, :show
  live "/users/:id/show/edit", UserLive.Show, :edit
end
```

### 步骤 6：运行迁移
```bash
mix ecto.migrate
```

### 步骤 7：更新测试
- 添加验证测试
- 添加关联测试
- 测试边界情况

## 常见模式

### 金钱字段
```bash
mix phx.gen.live Shop Product products \
  name:string \
  price:decimal \
  sale_price:decimal
```

然后更新迁移：
```elixir
add :price, :decimal, precision: 10, scale: 2, null: false
add :sale_price, :decimal, precision: 10, scale: 2
```

### 软删除
添加到 schema：
```bash
deleted_at:datetime
```

更新迁移：
```elixir
add :deleted_at, :utc_datetime
create index(:products, [:deleted_at])
```

### 多态关联
```bash
mix phx.gen.schema Comments.Comment comments \
  body:text \
  commentable_type:string \
  commentable_id:integer
```

### 多租户（租户 ID）
```bash
mix phx.gen.live Accounts User users \
  organization_id:references:organizations \
  name:string \
  email:string
```

添加租户 + 字段的唯一约束：
```elixir
create unique_index(:users, [:organization_id, :email])
```

## 撤销生成器

如果需要回滚：
```bash
# 回滚迁移
mix ecto.rollback

# 手动删除生成的文件或使用：
mix phx.gen.context --undo Accounts User users
```

## 故障排除

**模块已存在：**
- 生成器不会覆盖现有文件
- 使用 `--merge-with-existing-context` 添加到现有 context
- 或手动集成生成的代码

**路由不工作：**
- 检查 router.ex 是否已更新
- 验证 pipe_through 是否匹配（:browser 或 :api）
- 添加路由后重启服务器

**迁移失败：**
- 检查是否有重复的表名
- 验证引用的表是否存在
- 确保字段类型有效

## 生成器标志

```bash
# 跳过迁移
mix phx.gen.context Accounts User users name:string --no-migration

# 二进制 ID（UUID）
mix phx.gen.schema Accounts User users name:string --binary-id

# 与现有 context 合并
mix phx.gen.context Accounts Profile profiles bio:text --merge-with-existing-context

# 指定表名
mix phx.gen.schema Accounts User my_users name:string --table my_users
```
