# Ecto 最佳实践检查清单

在使用 Ecto schemas、migrations 和数据库操作时使用此检查清单。

## Schema 设计

### 字段
- [ ] 所有字段都有适当的类型（:string、:integer、:decimal、:utc_datetime 等）
- [ ] 字符串长度限制已定义（如适用）
- [ ] 货币/货币字段的小数精度已定义
- [ ] 枚举字段使用 Ecto.Enum 和值列表
- [ ] 虚拟字段标记为 `virtual: true`
- [ ] 默认值在数据库中设置，而不是在 schema 中（虚拟字段除外）

### 关联
- [ ] belongs_to 关联有对应的 foreign_key
- [ ] has_many 关联在需要时在两个方向上定义
- [ ] many_to_many 使用连接表或 has_many :through
- [ ] 外键有 on_delete 策略（:delete_all、:nilify_all、:nothing）
- [ ] 避免或仔细管理循环关联

### 时间戳
- [ ] 使用 `timestamps()` 宏
- [ ] 如果不是默认值，指定类型：`timestamps(type: :utc_datetime)`
- [ ] 手动时间戳字段使用 :utc_datetime，而不是 :naive_datetime

## Changesets

### 验证
- [ ] `cast/3` 仅包含可填充的字段
- [ ] 在所有必填字段上使用 `validate_required/2`
- [ ] 字符串格式已验证（电子邮件、URL 等）
- [ ] 数字范围已验证（最小值、最大值）
- [ ] 字符串长度已验证
- [ ] 复杂规则的自定义验证
- [ ] 虚拟字段已验证（如果使用）

### 约束
- [ ] 为唯一索引使用 `unique_constraint`
- [ ] 为外键使用 `foreign_key_constraint`
- [ ] 为数据库级检查使用 `check_constraint`
- [ ] 使用 `no_assoc_constraint` 防止删除关联
- [ ] 约束在数据库操作后运行

### 嵌入式 Schemas
- [ ] 为 JSON 字段使用嵌入式 schemas
- [ ] 根据需要使用 `embeds_one` 或 `embeds_many`
- [ ] 嵌入式 changesets 上的验证
- [ ] JSON 编码/解码已处理

## Migrations

### 结构
- [ ] Migration 文件有描述性名称
- [ ] 每个 migration 一个逻辑更改
- [ ] Migrations 是可逆的（`down` 函数或 `change`）
- [ ] 上升和下降已测试
- [ ] 尽可能幂等

### 表
- [ ] 主键已定义（通常是 bigserial `id`）
- [ ] 时间戳已添加（`timestamps()`）
- [ ] 外键引用正确的表
- [ ] 指定了删除/更新操作
- [ ] 表名是复数形式

### 索引
- [ ] 为唯一约束创建唯一索引
- [ ] 外键有索引
- [ ] 常见查询字段已索引
- [ ] 多列查询的复合索引
- [ ] 索引名称遵循约定或显式设置

### 数据类型
- [ ] 每列的适当类型
- [ ] 无限制字符串使用 :text
- [ ] 受限字符串使用 :string 和限制
- [ ] 货币使用 :decimal（不是 :float）
- [ ] 时间戳使用 :utc_datetime
- [ ] JSON 数据使用 :map 或 :jsonb

### 约束
- [ ] 必填字段上的 NOT NULL
- [ ] 业务规则的 CHECK 约束
- [ ] 根据需要的 UNIQUE 约束
- [ ] 外键约束
- [ ] 合理的默认值

## 查询

### 查询构造
- [ ] 使用 Ecto.Query DSL，而不是原始 SQL
- [ ] 查询是可组合的（使用 from、where、select 等）
- [ ] 预加载关联以避免 N+1
- [ ] 按关联过滤时使用 join
- [ ] 复杂查询时根据需要使用 subquery

### 预加载
- [ ] 简单关联使用 `preload`
- [ ] 过滤关联使用 `preload: [assoc: query]`
- [ ] 尽可能在单个查询中预加载
- [ ] 避免在循环中预加载

### 性能
- [ ] 没有 N+1 查询（使用 preload 或 join）
- [ ] 在大型查询中仅选择需要的字段
- [ ] 大型结果集的分页
- [ ] 仅需要某些记录时使用 limit
- [ ] 索引支持 WHERE 子句

### 事务
- [ ] 多步骤操作使用 Repo.transaction
- [ ] 复杂事务使用 Ecto.Multi
- [ ] 错误时回滚
- [ ] 保持事务简短

## 存储库操作

### 插入/更新/删除
- [ ] 使用上下文函数，而不是直接调用 Repo
- [ ] 处理 {:ok, result} 和 {:error, changeset} 元组
- [ ] 失败应该抛出异常时使用 bang 变体（!）
- [ ] 批量插入使用 insert_all
- [ ] 批量更新使用 update_all

### 错误处理
- [ ] Changeset 错误对用户友好
- [ ] 已处理约束违反错误
- [ ] 已处理数据库连接错误
- [ ] 已适当处理超时错误

## 多租户

如果实现多租户：

### Schema 级别
- [ ] 所有相关表上的 tenant_id
- [ ] 唯一约束中的 tenant_id
- [ ] 外键在适当时限定到租户
- [ ] 数据隔离已验证

### 查询级别
- [ ] 所有查询按 tenant_id 过滤
- [ ] 没有跨租户数据泄漏
- [ ] 每个租户的授权检查
- [ ] 测试验证租户隔离

## 测试

### Schema 测试
- [ ] Changeset 验证已测试
- [ ] 必填字段已测试
- [ ] 格式验证已测试（电子邮件等）
- [ ] 唯一约束已测试
- [ ] 外键约束已测试
- [ ] 自定义验证已测试

### 查询测试
- [ ] 查询返回预期结果
- [ ] 过滤器正常工作
- [ ] 预加载正常工作
- [ ] 边界情况已测试（空结果等）

## 示例

### 良好的 Schema 设计
```elixir
schema "users" do
  field :email, :string
  field :name, :string
  field :role, Ecto.Enum, values: [:admin, :user, :guest]
  field :password, :string, virtual: true
  field :password_hash, :string

  belongs_to :organization, Organization
  has_many :posts, Post
  has_many :comments, Comment

  timestamps(type: :utc_datetime)
end

def changeset(user, attrs) do
  user
  |> cast(attrs, [:email, :name, :role, :password, :organization_id])
  |> validate_required([:email, :name, :organization_id])
  |> validate_format(:email, ~r/@/)
  |> validate_length(:name, min: 2, max: 100)
  |> validate_inclusion(:role, [:admin, :user, :guest])
  |> unique_constraint(:email)
  |> foreign_key_constraint(:organization_id)
  |> hash_password()
end
```

### 良好的 Migration
```elixir
def change do
  create table(:users) do
    add :email, :string, null: false
    add :name, :string, null: false
    add :role, :string, null: false, default: "user"
    add :password_hash, :string, null: false
    add :organization_id, references(:organizations, on_delete: :delete_all), null: false

    timestamps(type: :utc_datetime)
  end

  create unique_index(:users, [:email])
  create index(:users, [:organization_id])
  create index(:users, [:email, :organization_id])
end
```

### 良好的查询
```elixir
def list_active_users_with_posts(organization_id) do
  from(u in User,
    where: u.organization_id == ^organization_id,
    where: u.active == true,
    preload: [:posts],
    order_by: [desc: u.inserted_at]
  )
  |> Repo.all()
end
```

## 常见陷阱

❌ **为货币使用浮点数**
```elixir
field :price, :float  # 错误 - 精度问题
field :price, :decimal  # 正确
```

❌ **N+1 查询**
```elixir
# 不好 - N+1 查询
users = Repo.all(User)
Enum.map(users, fn user -> user.posts end)  # 为每个用户查询！

# 好 - 预加载
users = Repo.all(User) |> Repo.preload(:posts)
Enum.map(users, fn user -> user.posts end)  # 已加载
```

❌ **不使用约束**
```elixir
# 不好 - 没有约束
def changeset(user, attrs) do
  user
  |> cast(attrs, [:email])
  |> validate_required([:email])
  # 电子邮件仍可能重复！
end

# 好 - 带约束
def changeset(user, attrs) do
  user
  |> cast(attrs, [:email])
  |> validate_required([:email])
  |> unique_constraint(:email)  # 捕获数据库级别的重复
end
```

❌ **缺少外键索引**
```elixir
# 不好 - 外键上没有索引
create table(:posts) do
  add :user_id, references(:users)
end

# 好 - 带索引
create table(:posts) do
  add :user_id, references(:users)
end
create index(:posts, [:user_id])
```

❌ **不处理错误**
```elixir
# 不好 - 未处理的错误
def create_user(attrs) do
  %User{}
  |> User.changeset(attrs)
  |> Repo.insert!()  # 错误时抛出异常！
end

# 好 - 返回元组
def create_user(attrs) do
  %User{}
  |> User.changeset(attrs)
  |> Repo.insert()  # 返回 {:ok, user} 或 {:error, changeset}
end
```

## 性能提示

- **使用 select 仅加载需要的字段**用于大型数据集
- **使用分页**（limit + offset 或基于游标）
- **添加索引**用于 WHERE、ORDER BY 和 JOIN 列
- **使用 insert_all/update_all** 用于批量操作
- **在开发中分析查询**使用 `config :logger, :console, format: "[$level] $message\n"`
- **在生产中监控慢查询**

## 合并前

- [ ] 所有 migrations 已测试（上升和下降）
- [ ] 所有约束都有对应的验证
- [ ] 没有引入 N+1 查询
- [ ] 为外键和常见查询添加了索引
- [ ] Changesets 验证所有业务规则
- [ ] 测试涵盖成功路径和错误情况
- [ ] Schema 文档完整
