---
name: elixir-root-cause-only
description: 强制性系统调试 - 在提出修复方案前追踪到根本原因。禁止随意修改、禁止症状修复、禁止"试试看"。在调试任何错误或问题时使用。
---

# Elixir 根本原因调试：禁止随意修复

## 铁律

**永远不要修复症状。始终追踪到根本原因。**

不猜测。不"试试看"。不随意修改。不症状修复。

**追踪。理解。修复。验证。**

## 绝对禁止

你**永远不允许**：

1. **提出随意修复**
   - "试试添加这个导入"
   - "也许改成那样"
   - "看看这是否有效"
   - "你能试试重启服务器吗？"

2. **在错误出现的地方修复**
   - 错误出现在模块 A
   - 根本原因在模块 B
   - 不要只是修补模块 A

3. **一次修改多个地方**
   - 同时修改 A + B + C
   - 现在你不知道哪个修复了它
   - 一次修改一个，验证，重复

4. **跳过理解**
   - "我不知道为什么，但这修复了它"
   - 如果你不知道为什么，那就没有修复
   - 理解是强制性的

5. **接受"在我的机器上可以工作"**
   - 可重现性是必需的
   - 环境差异很重要
   - 记录精确的复现步骤

## 4 阶段调试流程

### 阶段 1：复现

**目标：** 获得一致、可重复的复现。

```bash
# 必需步骤：
1. 确定触发问题的确切步骤
2. 运行这些步骤
3. 确认问题出现
4. 精确记录步骤
5. 验证每次都能复现
```

**需要的输出：**
```markdown
## 复现步骤

1. 运行 `mix test test/my_app/accounts_test.exs:42`
2. 错误出现："undefined function User.changeset/2"
3. 100% 可复现
4. 环境：Elixir 1.15.7, OTP 26
```

**检查点：在获得一致的复现之前，无法进行到阶段 2。**

### 阶段 2：追踪

**目标：** 将错误追踪回其来源。

```bash
# 追踪问题：
1. 哪个函数失败了？
2. 什么调用了那个函数？
3. 什么调用了那个函数？
4. 坏数据/状态从哪里来的？
5. 第一个出错的地方是哪里？
```

**追踪工具：**
```elixir
# 1. 添加 IO.inspect 查看数据流
def create_user(attrs) do
  attrs
  |> IO.inspect(label: "Input attrs")
  |> User.changeset(%User{})
  |> IO.inspect(label: "Changeset")
  |> Repo.insert()
end

# 2. 使用 IEx.pry 进行交互式调试
def create_user(attrs) do
  require IEx; IEx.pry()
  # 执行在此暂停
  User.changeset(%User{}, attrs)
  |> Repo.insert()
end

# 3. 完整检查堆栈跟踪
** (UndefinedFunctionError) function User.changeset/2 is undefined
    (my_app 0.1.0) lib/my_app/accounts/user.ex:42: User.changeset/2
    (my_app 0.1.0) lib/my_app/accounts.ex:15: MyApp.Accounts.create_user/1
    test/my_app/accounts_test.exs:25: (test)
```

**需要的输出：**
```markdown
## 根本原因追踪

错误出现：lib/my_app/accounts.ex:15
调用来自：test/my_app/accounts_test.exs:25
根本原因：lib/my_app/accounts/user.ex:42
原因：User.changeset/2 未定义（应该是 User.changeset/1）
```

**检查点：在识别根本原因之前，无法进行到阶段 3。**

### 阶段 3：修复

**目标：** 修复根本原因，而不是症状。

```elixir
# 不好：在错误出现的地方修复
# 在 accounts.ex 中
def create_user(attrs) do
  # 捕获错误并绕过它
  try do
    User.changeset(%User{}, attrs)
  rescue
    UndefinedFunctionError ->
      User.new_changeset(%User{}, attrs)  # 症状修复！
  end
end

# 好：修复根本原因
# 在 user.ex 中 - 修复实际的函数定义
defmodule MyApp.Accounts.User do
  def changeset(user \\ %User{}, attrs) do  # ← 修复了元数
    user
    |> cast(attrs, [:name, :email])
    |> validate_required([:name, :email])
  end
end
```

**需要的输出：**
```markdown
## 应用的修复

位置：lib/my_app/accounts/user.ex:42
修改：将 `changeset/2` 改为 `changeset/1`，带默认参数
原因：函数被调用时有 2 个参数，但只定义了 1 个
```

**检查点：修复必须解决根本原因，而不是症状。**

### 阶段 4：验证

**目标：** 证明修复有效且没有破坏其他东西。

```bash
# 必需验证：
1. 运行失败的测试/命令
2. 确认现在通过
3. 运行完整测试套件
4. 确认没有回归
5. 记录验证
```

**需要的输出：**
```markdown
## 验证

$ mix test test/my_app/accounts_test.exs:42
.
1 test, 0 failures ✓

$ mix test
..........
10 tests, 0 failures ✓

根本原因已修复，无回归。
```

**检查点：在验证之前，无法声称完成。**

## 根本原因追踪示例

### 示例 1：Dialyzer 类型错误

**错误：**
```
lib/my_app/billing.ex:42:pattern_can_never_match
Pattern {:ok, amount} can never match type {:error, :invalid}
```

**错误的方法（症状修复）：**
```elixir
# 只是添加到 dialyzer.ignore
```

**正确的方法（根本原因）：**

**阶段 1 - 复现：**
```bash
$ mix dialyzer
# 错误一致出现
```

**阶段 2 - 追踪：**
```elixir
# lib/my_app/billing.ex:42
def process_payment(user_id, amount) do
  case validate_amount(amount) do
    {:ok, amount} -> charge(user_id, amount)  # 第 42 行
    {:error, reason} -> {:error, reason}
  end
end

# 追踪回 validate_amount/1
def validate_amount(amount) when amount > 0 do
  {:ok, amount}
end
def validate_amount(_amount) do
  {:error, :invalid}  # 这是唯一的返回值！
end
```

**根本原因：** `validate_amount/1` 对于非正数总是返回 `{:error, :invalid}`，所以 `{:ok, amount}` 模式永远无法匹配错误情况。

**阶段 3 - 修复：**
```elixir
# 修复逻辑 - validate_amount 应该为有效金额返回 {:ok, amount}
def validate_amount(amount) when amount > 0 do
  {:ok, amount}
end
def validate_amount(_amount) do
  {:error, :invalid_amount}
end

# 或修复模式匹配以处理实际返回类型
def process_payment(user_id, amount) do
  case validate_amount(amount) do
    {:ok, valid_amount} -> charge(user_id, valid_amount)
    {:error, :invalid_amount} -> {:error, :invalid_amount}
  end
end
```

**阶段 4 - 验证：**
```bash
$ mix dialyzer
Total errors: 0, Skipped: 0
done (passed successfully)
```

### 示例 2：测试失败

**错误：**
```
test create_user with valid attrs (MyApp.AccountsTest)
** (KeyError) key :email not found
```

**错误的方法（症状修复）：**
```elixir
# 只是添加默认邮箱
test "create_user with valid attrs" do
  attrs = Map.put(%{name: "Alice"}, :email, "default@example.com")
  # ...
end
```

**正确的方法（根本原因）：**

**阶段 1 - 复现：**
```bash
$ mix test test/my_app/accounts_test.exs:42
** (KeyError) key :email not found
```

**阶段 2 - 追踪：**
```elixir
# 测试代码
test "create_user with valid attrs" do
  attrs = %{name: "Alice"}  # 缺少 :email
  assert {:ok, user} = Accounts.create_user(attrs)  # 在此失败
end

# 追踪到 create_user
def create_user(attrs) do
  %User{}
  |> User.changeset(attrs)
  |> Repo.insert()
end

# 追踪到 changeset
def changeset(user, attrs) do
  user
  |> cast(attrs, [:name, :email])
  |> validate_required([:name, :email])  # 需要 :email！
  |> validate_format(:email, ~r/@/)      # 访问 attrs.email
end
```

**根本原因：** 测试 fixture 不包含必需的 :email 字段。schema 验证需要 :email，但测试 attrs 没有提供。

**阶段 3 - 修复：**
```elixir
# 修复测试以提供必需数据
test "create_user with valid attrs" do
  attrs = %{name: "Alice", email: "alice@example.com"}
  assert {:ok, user} = Accounts.create_user(attrs)
  assert user.name == "Alice"
  assert user.email == "alice@example.com"
end

# 或者如果邮箱不应该是必需的，修复 schema
def changeset(user, attrs) do
  user
  |> cast(attrs, [:name, :email])
  |> validate_required([:name])  # 邮箱是可选的
end
```

**阶段 4 - 验证：**
```bash
$ mix test test/my_app/accounts_test.exs:42
.
1 test, 0 failures
```

### 示例 3：N+1 查询问题

**症状：**
```
GET /users - 342ms (太慢！)
```

**错误的方法（症状修复）：**
```elixir
# 只是添加缓存
def list_users do
  Cachex.get_or_store(:users, fn ->
    Repo.all(User)
  end)
end
```

**正确的方法（根本原因）：**

**阶段 1 - 复现：**
```bash
# 启用查询日志
config :logger, level: :debug

$ curl localhost:4000/users
# 日志显示：
SELECT * FROM users
SELECT * FROM posts WHERE user_id = 1
SELECT * FROM posts WHERE user_id = 2
SELECT * FROM posts WHERE user_id = 3
# ... 100 个用户共 100 个查询
```

**阶段 2 - 追踪：**
```elixir
# 控制器
def index(conn, _params) do
  users = Accounts.list_users()
  render(conn, "index.html", users: users)
end

# 视图模板
<%= for user <- @users do %>
  <div>
    <%= user.name %>
    Posts: <%= length(user.posts) %>  # ← N+1 触发！
  </div>
<% end %>

# 上下文
def list_users do
  Repo.all(User)  # 没有预加载 posts
end
```

**根本原因：** 视图访问 `user.posts` 为每个用户触发单独的查询。上下文没有预加载关联。

**阶段 3 - 修复：**
```elixir
# 修复：在上下文中预加载
def list_users do
  User
  |> Repo.all()
  |> Repo.preload(:posts)
end
```

**阶段 4 - 验证：**
```bash
$ curl localhost:4000/users
# 日志显示：
SELECT * FROM users
SELECT * FROM posts WHERE user_id IN (1, 2, 3, ..., 100)
# 2 个查询而不是 101 个！

# 响应时间：342ms → 45ms
```

## 调试工具

### IEx.pry - 交互式调试
```elixir
def create_user(attrs) do
  require IEx; IEx.pry()
  # 执行暂停，你可以检查：
  # > attrs
  # > User.__struct__()
  # > continue 继续
  User.changeset(%User{}, attrs)
end
```

### IO.inspect - 数据检查
```elixir
def create_user(attrs) do
  attrs
  |> IO.inspect(label: "Raw attrs")
  |> Map.put(:inserted_at, DateTime.utc_now())
  |> IO.inspect(label: "With timestamp")
  |> User.changeset(%User{})
  |> IO.inspect(label: "Changeset")
end
```

### Logger - 生产调试
```elixir
require Logger

def create_user(attrs) do
  Logger.debug("Creating user with attrs: #{inspect(attrs)}")

  case User.changeset(%User{}, attrs) |> Repo.insert() do
    {:ok, user} ->
      Logger.info("User created: #{user.id}")
      {:ok, user}
    {:error, changeset} ->
      Logger.error("Failed to create user: #{inspect(changeset.errors)}")
      {:error, changeset}
  end
end
```

### Observer - 系统监控
```bash
# 启动 Observer GUI
iex -S mix
iex> :observer.start()

# 显示：
# - 进程树
# - 内存使用
# - 消息队列
# - ETS 表
```

### Recon - 生产追踪
```elixir
# 查找慢进程
:recon.proc_window(:memory, 3, 1000)

# 追踪函数调用
:recon_trace.calls({MyApp.Accounts, :create_user, :return_trace}, 10)
```

## 错误的理由

### "让我们试试这个看看是否有效"
**错误。** 随意修改浪费时间。先追踪到根本原因。

### "我 90% 确定这是修复"
**错误。** 90% 确定 = 10% 破损。通过追踪达到 100%。

### "我们可以在生产中调试"
**错误。** 在开发中调试，那里你有完整的工具并可以破坏东西。

### "错误消息不清楚"
**错误。** 错误消息是精确的。完整仔细地阅读它们。

### "这可能是竞态条件"
**错误。** "可能"意味着你还没有追踪。竞态条件可以用正确的工具复现。

### "让我们改多个东西以确保"
**错误。** 一次修改一个，验证，重复。多个修改 = 混乱。

## 禁止短语

❌ "试试这个"
❌ "也许这会有效"
❌ "让我们看看"
❌ "你能试试"
❌ "我认为问题是"
❌ "只是重启它"
❌ "清除缓存"
❌ "在我的机器上可以工作"
❌ "我不确定为什么，但"
❌ "这是一个海森堡虫"

**相反：** 追踪、理解、确定地修复。

## 系统调试检查清单

在提出任何修复之前：

- [ ] 我可以一致地复现问题
- [ ] 我有确切的错误消息
- [ ] 我已读完整个堆栈跟踪
- [ ] 我已从错误追踪到根本原因
- [ ] 我理解为什么会出现错误
- [ ] 我知道第一个出错的地方
- [ ] 我的修复解决根本原因（不是症状）
- [ ] 我已验证修复有效
- [ ] 我已验证没有回归
- [ ] 我可以清楚地解释根本原因

**如果你无法勾选所有框，继续追踪。**

## 规则

**没有理解就没有修复。**

**没有追踪就没有修改。**

**仅根本原因。始终。**

## 记住

> "错误出现在问题被检测到的地方，而不是它起源的地方。"

> "症状是可见的。根本原因必须被追踪。"

> "随意修复可能意外有效。理解有目的地有效。"

**追踪。理解。修复。验证。**
