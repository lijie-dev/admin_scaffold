---
name: elixir-no-placeholders
description: 禁止占位符代码、隐藏缺失数据的默认值和静默失败。强制快速失败并产生明显的错误。在实现任何函数或数据结构时使用。
---

# Elixir 无占位符：大声失败，快速失败

## 铁律

**永远不要创建占位符代码或在不应该有默认值的地方提供默认值。**

静默失败是调试的噩梦。大声失败可以节省数小时的故障排除时间。

**大声失败。快速失败。明显失败。**

## 绝对禁止

你**永远不允许**：

### 1. 创建占位符代码

```elixir
# 不好：占位符实现
def process_payment(_user_id, _amount) do
  # TODO: 实现这个
  {:ok, %{}} # 错误！使用空数据的静默成功
end

def send_email(_to, _subject, _body) do
  :ok  # 错误！假装工作但什么都不做
end

def validate_user(_attrs) do
  {:ok, attrs}  # 错误！绕过验证
end

# 好：明确的未实现
def process_payment(_user_id, _amount) do
  raise "process_payment/2 未实现"
end

# 或使用 @impl 和适当的错误
@impl true
def handle_call({:process_payment, user_id, amount}, _from, state) do
  {:stop, {:error, :not_implemented}, state}
end
```

### 2. 提供隐藏缺失数据的默认值

```elixir
# 不好：默认值隐藏缺失的必需数据
defmodule User do
  schema "users" do
    field :email, :string, default: "unknown@example.com"  # 错误！
    field :name, :string, default: "Unknown User"          # 错误！
    field :role, :string, default: "user"                  # 如果真正可选可能没问题
  end
end

# 好：必需字段没有默认值
defmodule User do
  schema "users" do
    field :email, :string  # 必需 - 无默认值
    field :name, :string   # 必需 - 无默认值
    field :role, :string, default: "user"  # 可以 - 有明确的默认值含义
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :role])
    |> validate_required([:email, :name])  # 明确的要求
  end
end
```

### 3. 模式匹配中的静默回退

```elixir
# 不好：捕获所有隐藏问题
def handle_result({:ok, data}), do: process(data)
def handle_result({:error, reason}), do: log_error(reason)
def handle_result(_anything_else), do: :ok  # 错误！静默成功

# 好：明确处理，意外输入时崩溃
def handle_result({:ok, data}), do: process(data)
def handle_result({:error, reason}), do: {:error, reason}
# 没有捕获所有 - 如果输入意外会大声崩溃

# 或如果必须处理则明确错误
def handle_result(unexpected) do
  raise ArgumentError, "期望 {:ok, data} 或 {:error, reason}，得到：#{inspect(unexpected)}"
end
```

### 4. 空数据结构作为回退

```elixir
# 不好：返回空而不是错误
def get_user_posts(user_id) do
  case Repo.get(User, user_id) do
    nil -> []  # 错误！静默的"无帖子"vs"用户不存在"
    user -> Repo.preload(user, :posts).posts
  end
end

# 好：缺失用户时明确错误
def get_user_posts(user_id) do
  user = Repo.get!(User, user_id)  # 如果用户缺失则崩溃
  Repo.preload(user, :posts).posts
end

# 或返回适当的错误元组
def get_user_posts(user_id) do
  case Repo.get(User, user_id) do
    nil -> {:error, :user_not_found}
    user -> {:ok, Repo.preload(user, :posts).posts}
  end
end
```

### 5. 静默错误的 Try/Rescue

```elixir
# 不好：捕获并返回默认值
def parse_date(date_string) do
  try do
    Date.from_iso8601!(date_string)
  rescue
    _ -> ~D[2000-01-01]  # 错误！为什么是这个日期？隐藏解析错误
  end
end

# 好：让它崩溃或返回错误
def parse_date(date_string) do
  Date.from_iso8601!(date_string)  # 以清晰的错误崩溃
end

# 或返回明确的错误
def parse_date(date_string) do
  case Date.from_iso8601(date_string) do
    {:ok, date} -> {:ok, date}
    {:error, reason} -> {:error, {:invalid_date, reason}}
  end
end
```

### 6. 对必需键使用 Map.get/3 和默认值

```elixir
# 不好：默认值隐藏缺失的必需键
def create_user(attrs) do
  email = Map.get(attrs, :email, "unknown@example.com")  # 错误！
  name = Map.get(attrs, :name, "Unknown")                # 错误！
  User.changeset(%User{}, %{email: email, name: name})
end

# 好：如果键缺失则让它崩溃
def create_user(attrs) do
  # 如果 :email 或 :name 缺失会抛出 KeyError - 好！
  %{email: email, name: name} = attrs
  User.changeset(%User{}, %{email: email, name: name})
end

# 或明确的错误
def create_user(attrs) do
  with {:ok, email} <- Map.fetch(attrs, :email),
       {:ok, name} <- Map.fetch(attrs, :name) do
    User.changeset(%User{}, %{email: email, name: name})
  else
    :error -> {:error, :missing_required_fields}
  end
end
```

### 7. 带有静默回退的配置

```elixir
# 不好：默认配置隐藏缺失的环境变量
def api_key do
  System.get_env("API_KEY") || "default_key_12345"  # 错误！
end

def database_url do
  System.get_env("DATABASE_URL") || "localhost"  # 错误！
end

# 好：如果必需的环境变量缺失则崩溃
def api_key do
  System.fetch_env!("API_KEY")  # 如果缺失则崩溃
end

def database_url do
  System.get_env("DATABASE_URL") ||
    raise "DATABASE_URL 环境变量是必需的"
end
```

## 何时默认值是可接受的

当默认值具有**语义含义**而不仅仅是占位符时，默认值是可以的：

### 可接受的默认值

```elixir
# 可以：默认值有实际的业务含义
defmodule Post do
  schema "posts" do
    field :status, :string, default: "draft"        # 可以：新帖子是草稿
    field :published, :boolean, default: false      # 可以：默认未发布
    field :view_count, :integer, default: 0         # 可以：初始无浏览
    field :featured, :boolean, default: false       # 可以：默认未精选
  end
end

# 可以：具有合理默认值的可选字段
def create_user(email, name, opts \\ []) do
  role = Keyword.get(opts, :role, "user")          # 可以："user" 是合理的默认值
  locale = Keyword.get(opts, :locale, "en")        # 可以："en" 是合理的默认值
  %User{email: email, name: name, role: role, locale: locale}
end

# 可以：分页默认值
def list_users(opts \\ []) do
  page = Keyword.get(opts, :page, 1)               # 可以：第 1 页是合理的起点
  per_page = Keyword.get(opts, :per_page, 20)      # 可以：20 是合理的页面大小

  User
  |> limit(^per_page)
  |> offset(^((page - 1) * per_page))
  |> Repo.all()
end
```

### 不可接受的默认值（占位符）

```elixir
# 错误：默认值隐藏缺失的必需数据
field :email, :string, default: "unknown@example.com"     # 用户邮箱是必需的！
field :stripe_customer_id, :string, default: "cus_xxxxx"  # 支付 ID 是必需的！
field :api_token, :string, default: "token123"            # 安全凭证！

# 错误：默认值绕过验证
def validate_amount(amount) do
  amount || 0  # 如果 amount 是 nil，使用 0 - 错误！
end

# 错误：默认值隐藏配置错误
api_endpoint = System.get_env("API_ENDPOINT") || "http://localhost"  # 生产环境会崩溃！
```

## 检测清单

在写任何默认值之前，问自己：

1. **这个数据真的是可选的吗？** → 如果不是，不要提供默认值
2. **这个默认值有语义含义吗？** → 如果没有，不要提供默认值
3. **我是否宁愿立即知道这个缺失？** → 如果是，不要提供默认值
4. **这个默认值会隐藏 bug 吗？** → 如果是，不要提供默认值
5. **这是配置值吗？** → 如果是，缺失时崩溃

**如有疑问，不要默认值。让它崩溃。**

## 大声失败的模式

### 模式 1：让它崩溃

```elixir
# 更倾向于这个
def process_order(order_id) do
  order = Repo.get!(Order, order_id)  # ! 版本在未找到时崩溃
  Repo.preload(order, :items)
end

# 而不是这个
def process_order(order_id) do
  case Repo.get(Order, order_id) do
    nil -> %Order{}  # 错误！没有数据的假订单
    order -> Repo.preload(order, :items)
  end
end
```

### 模式 2：明确的错误

```elixir
# 当你需要处理缺失的数据时
def find_user(id) do
  case Repo.get(User, id) do
    nil -> {:error, :user_not_found}       # 明确的错误
    user -> {:ok, user}                     # 明确的成功
  end
end

# 不是这个
def find_user(id) do
  Repo.get(User, id) || %User{}  # 错误！假用户
end
```

### 模式 3：必需的键

```elixir
# 使用模式匹配强制必需的键
def create_notification(%{user_id: user_id, message: message} = attrs) do
  # 如果 user_id 或 message 缺失会以清晰的错误崩溃
  %Notification{user_id: user_id, message: message}
end

# 不是这个
def create_notification(attrs) do
  user_id = attrs[:user_id] || 1       # 错误！谁是用户 1？
  message = attrs[:message] || "N/A"   # 错误！无用的通知
  %Notification{user_id: user_id, message: message}
end
```

### 模式 4：配置必需

```elixir
# 在 config/runtime.exs 中
config :my_app, MyApp.Mailer,
  adapter: Swoosh.Adapters.Sendgrid,
  api_key: System.fetch_env!("SENDGRID_API_KEY")  # 缺失时崩溃

# 不是这个
config :my_app, MyApp.Mailer,
  adapter: Swoosh.Adapters.Sendgrid,
  api_key: System.get_env("SENDGRID_API_KEY") || "default"  # 错误！
```

## 调试的好处

**使用占位符和默认值：**
```
用户注册成功 ✓
电子邮件通知"已发送" ✓
数据库显示：user.email = "unknown@example.com"
客户："我从未收到确认邮件！"
开发者："哦，邮箱一直就是 'unknown@example.com'..."
调试时间：2 小时追踪日志
```

**不使用占位符（大声失败）：**
```
用户注册失败 ✗
错误："参数中未找到必需的键 :email"
开发者："邮箱字段在表单中缺失"
调试时间：2 分钟添加邮箱字段
```

## 真实调试噩梦的例子

### 例子 1：静默支付失败

```elixir
# 不好：带占位符的静默失败
def charge_customer(amount) do
  stripe_customer_id = get_stripe_id() || "cus_placeholder"  # 错误！

  case Stripe.charge(stripe_customer_id, amount) do
    {:ok, charge} -> {:ok, charge}
    {:error, _} -> {:ok, %{id: "ch_placeholder", status: "succeeded"}}  # 错误！
  end
end

# 结果：数据库显示成功收费，客户从未被收费，调试需要数天

# 好：大声失败
def charge_customer(amount) do
  stripe_customer_id = get_stripe_id!()  # 缺失时崩溃

  case Stripe.charge(stripe_customer_id, amount) do
    {:ok, charge} -> {:ok, charge}
    {:error, reason} -> {:error, reason}  # 明确的错误
  end
end

# 结果：错误立即出现，5 分钟内修复
```

### 例子 2：默认值隐藏配置错误

```elixir
# 不好：默认值隐藏缺失的配置
defmodule MyApp.EmailClient do
  def send(to, subject, body) do
    api_key = System.get_env("EMAIL_API_KEY") || "test_key_123"  # 错误！
    # 在开发中工作，在生产中静默失败
    ThirdPartyMailer.send(api_key, to, subject, body)
  end
end

# 好：早期崩溃
defmodule MyApp.EmailClient do
  def send(to, subject, body) do
    api_key = System.fetch_env!("EMAIL_API_KEY")  # 启动时崩溃
    ThirdPartyMailer.send(api_key, to, subject, body)
  end
end
```

### 例子 3：空列表隐藏数据库问题

```elixir
# 不好：空列表隐藏查询错误
def user_orders(user_id) do
  try do
    Repo.all(from o in Order, where: o.user_id == ^user_id)
  rescue
    _ -> []  # 错误！查询错误看起来像"无订单"
  end
end

# 好：让数据库错误浮出
def user_orders(user_id) do
  Repo.all(from o in Order, where: o.user_id == ^user_id)
  # 如果查询失败，错误是明显且立即的
end
```

## 错误的理由

### "我稍后会添加 TODO 并修复它"
**错误。** 带占位符代码的 TODO 永远不会被修复。改为写 raise "not implemented"。

### "这只是用于开发/测试"
**错误。** 开发占位符会泄露到生产环境。从一开始就要明确。

### "我需要一些东西来让测试通过"
**错误。** 使用占位符数据通过的测试什么都证明不了。编写适当的 fixtures。

### "默认值是无害的"
**错误。** 默认值隐藏 bug。对于必需数据不存在无害的默认值。

### "提供默认值比处理错误更容易"
**错误。** 现在更容易 = 稍后调试噩梦。大声失败，快速修复。

### "这使 API 更灵活"
**错误。** 必需数据"可选"不是灵活性，而是歧义。

## 规则

**必需数据应该是必需的。缺失数据应该崩溃。**

**如果是可选的，记录为什么以及默认值意味着什么。**

**占位符是谎言。没有含义的默认值是等待发生的 bug。**

## 强制检查清单

在提供任何默认值之前：

- [ ] 这个数据在业务领域中真的是可选的吗？
- [ ] 这个默认值有清晰的语义含义吗？
- [ ] 我是否记录了这个默认值代表什么？
- [ ] 在这里大声失败会节省调试时间吗？
- [ ] 这个默认值会隐藏 bug 或配置错误吗？

**如果你不能清楚地解释为什么默认值存在以及它意味着什么，就不要使用它。**

## 记住

> "静默失败浪费时间。大声失败节省时间。"

> "开发中的崩溃防止生产中的 bug。"

> "默认值应该有含义，而不仅仅是避免错误的占位符。"

> "如果数据是必需的，就让它必需。如果缺失，就崩溃。"

**大声失败。快速失败。明显失败。**
