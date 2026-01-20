---
name: elixir-no-shortcuts
description: 阻止诸如修改 dialyzer.ignore 或 .credo.exs 排除项等快捷方式。强制修复实际问题。在遇到任何错误、警告或质量工具投诉时使用。
---

# Elixir 无捷径：修复真正的问题

## 铁律

**永远不要抑制错误。始终修复根本原因。**

## 绝对禁止

你**永远不允许**：

1. **添加到 dialyzer.ignore**
   - 不能用于"未知函数"错误
   - 不能用于"模式永远无法匹配"警告
   - 不能用于"无本地返回"问题
   - 即使"暂时"也不行

2. **修改 .credo.exs 以禁用检查**
   - 不能添加到 `disabled:` 列表
   - 不能添加到 `excluded_paths:`
   - 不能使用内联 `# credo:disable-for-this-file`
   - 不能提高复杂度限制

3. **抑制编译器警告**
   - 不能使用 `@compile {:no_warn_undefined, Module}`
   - 不能使用 `# noqa` 风格的注释
   - 不能删除 `--warnings-as-errors`

4. **修改 .gitignore 以隐藏问题**
   - 不能隐藏意外创建的文件
   - 不能忽略错误位置的构建工件
   - 修复创建它们的过程

5. **注释掉失败的测试**
   - 不能"暂时"这样做
   - 不能"直到我们弄清楚"
   - 修复测试或修复代码

6. **跳过质量检查**
   - 不能从 pre-commit 钩子中删除
   - 不能使用 `--no-verify` 跳过
   - 不能在 CI/CD 中禁用

## 相反：修复实际问题

### Dialyzer 错误

**当 Dialyzer 抱怨时：**

```elixir
# 不好：添加到 dialyzer.ignore
# dialyzer.ignore
lib/my_app/accounts.ex:42:pattern_can_never_match

# 好：使用正确的 @spec 修复
defmodule MyApp.Accounts do
  @spec get_user(integer()) :: {:ok, User.t()} | {:error, :not_found}
  def get_user(id) do
    case Repo.get(User, id) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end
end
```

**常见 Dialyzer 修复：**

1. **未知函数** - 添加 @spec 或导入模块
2. **模式永远无法匹配** - 修复实际的模式不匹配
3. **无本地返回** - 添加错误处理路径
4. **无效的类型规范** - 更正 @spec 以匹配现实

**流程：**
1. 完整阅读 Dialyzer 错误（不要只是扫一眼）
2. 理解 Dialyzer 在告诉你什么
3. 添加与函数实际执行内容匹配的 @spec
4. 如果函数行为错误，修复函数
5. 再次运行 `mix dialyzer` 以验证

### Credo 警告

**当 Credo 抱怨时：**

```elixir
# 不好：添加到 .credo.exs
{Credo.Check.Refactor.CyclomaticComplexity, max_complexity: 20}

# 好：重构以降低复杂度
# 之前：复杂的条件逻辑
def process(data, opts) do
  if opts[:validate] and opts[:transform] and not opts[:skip] do
    # ... 50 行嵌套逻辑
  end
end

# 之后：提取函数
def process(data, opts) do
  data
  |> maybe_validate(opts)
  |> maybe_transform(opts)
  |> finalize()
end

defp maybe_validate(data, %{validate: true}), do: validate(data)
defp maybe_validate(data, _opts), do: data
```

**常见 Credo 修复：**

1. **高复杂度** - 提取函数，使用管道
2. **长函数** - 分解为更小、更专注的函数
3. **嵌套太深** - 使用早期返回、with 语句或守卫子句
4. **模块太长** - 分解为多个专注的模块
5. **设计反模式** - 按照 Elixir 习语重构

**流程：**
1. 阅读 Credo 警告的原因
2. 理解它检测到的代码异味
3. 重构以消除异味
4. 运行 `mix credo --strict` 以验证

### 编译器警告

**当编译器警告时：**

```elixir
# 不好：抑制警告
@compile {:no_warn_undefined, SomeModule}

# 好：修复实际问题
# 如果函数不存在 - 实现它
# 如果模块不存在 - 添加依赖
# 如果是拼写错误 - 修复拼写错误
```

### 测试失败

**当测试失败时：**

```elixir
# 不好：注释掉测试
# test "user can login" do
#   # 这是坏的，稍后会修复
# end

# 好：修复测试或代码
test "user can login" do
  user = fixture(:user)
  assert {:ok, session} = Accounts.authenticate(user.email, "password")
  assert session.user_id == user.id
end
```

## 检测清单

**在进行任何文件修改之前，问自己：**

1. **我是否即将修改 `.ignore` 文件？** → 停止
2. **我是否即将添加到 `excluded:` 或 `disabled:` 列表？** → 停止
3. **我是否即将注释掉代码以消除错误？** → 停止
4. **我是否即将跳过质量检查？** → 停止
5. **我是否即将抑制警告？** → 停止

**如果任何答案是"是" → 使用此技能修复真正的问题。**

## 禁用短语

如果你即将说出以下任何短语，**立即停止**并使用此技能：

❌ "这是一个小警告"
❌ "这将在稍后实现"
❌ "这与我的更改无关"
❌ "这些警告可以安全地忽略"
❌ "我会添加一个 TODO 并稍后回到它"
❌ "这是一个假阳性"
❌ "代码工作正常，工具太挑剔了"
❌ "添加到忽略列表只是这一个情况"
❌ "这个函数现在太复杂了，无法重构"
❌ "让我们暂时禁用此检查"

**相反：** 现在修复实际问题。趁上下文还新鲜。

## 调试流程

当你遇到错误时：

### 第 1 步：完整阅读错误
- 不要扫一眼 - 逐字阅读
- 记下文件、行号和确切的消息
- 理解哪个工具在抱怨以及为什么

### 第 2 步：理解根本原因
- 为什么会发生这种情况？
- 代码实际在做什么与应该做什么？
- 工具想让我修复什么？

### 第 3 步：修复代码
- 添加缺失的 @spec 注释
- 重构复杂函数
- 修复模式匹配
- 添加错误处理
- 实现缺失的函数

### 第 4 步：验证修复
- 再次运行工具
- 看到错误已消失（不是被抑制）
- 所有测试仍然通过

## 错误的理由

### "这是工具的假阳性"
**错误。** 工具几乎总是对的。如果你认为它错了，你误解了以下之一：
- 你的代码做什么
- 工具在检查什么
- Elixir/Erlang 语义

### "我稍后会修复这个，只需要继续前进"
**错误。** "稍后"永远不会到来。趁上下文还新鲜时现在就修复。

### "代码工作正常，Dialyzer 只是太挑剔了"
**错误。** Dialyzer 发现了类型不一致。你的代码现在可能工作，但它很脆弱，当情况改变时会崩溃。

### "这个函数太复杂了，现在无法重构"
**错误。** 如果它太复杂了无法重构，它就太复杂了无法维护。现在重构它或永远受苦。

### "添加到忽略列表只是这一个情况"
**错误。** 一旦你开始忽略，你永远不会停止。忽略文件会越来越大。修复。代码。

### "测试不稳定，我就注释掉它"
**错误。** 不稳定的测试表明真实的问题（竞态条件、不当的设置/拆卸、环境依赖）。修复不稳定性。

### "这是一个小警告"
**错误。** 没有小警告。每个警告都是编译器/工具试图告诉你一些重要的事情。"小"警告会变成生产中的重大错误。

### "这将在稍后实现"
**错误。** 这是 TODO 地狱。要么现在实现它，要么根本不写代码。带有"TODO：稍后实现"的占位符实现永远不会被实现 - 它们会变成永久的技术债务。

### "这与我的更改无关"
**错误。** 你接触了代码，你拥有它。警告在你的监视下出现 - 修复它。"不是我的问题"的态度导致代码库腐烂。留下比你发现的更好的代码。

### "这些警告可以安全地忽略"
**错误。** 没有"可以安全地忽略"的警告。如果警告真的可以安全地忽略，工具就不会发出它。每个警告都有原因 - 理解它并修复代码。

## 采取捷径的后果

**如果你抑制而不是修复：**

1. **技术债务累积** - 未来的你会恨过去的你
2. **真实的错误隐藏** - 错误试图告诉你一些事情
3. **代码质量下降** - 破窗理论在起作用
4. **团队速度减慢** - 每个捷径都使下一个功能更难
5. **生产故障增加** - 被抑制的警告变成运行时错误

**通过添加到忽略列表"节省"的 5 分钟在稍后调试中花费 5 小时。**

## 执行

**在修改以下任何文件之前，你必须使用此技能：**

- `dialyzer.ignore`
- `.credo.exs`（特别是 `disabled:` 或 `excluded_paths:` 部分）
- 任何包含质量检查配置的文件
- `.gitignore`（当隐藏问题而不是适当的忽略模式时）
- 测试文件（当注释掉失败的测试时）

**如果你发现自己在输入"添加到忽略列表"，停止并修复真正的问题。**

## 正确修复的示例

### 示例 1：Dialyzer 未知函数

```elixir
# 错误：函数 MyApp.Repo.get/2 未定义或私有

# 不好：添加到 dialyzer.ignore
# 好：添加正确的类型
defmodule MyApp.Accounts do
  alias MyApp.Repo
  alias MyApp.Accounts.User

  @spec get_user(integer()) :: User.t() | nil
  def get_user(id) do
    Repo.get(User, id)
  end
end
```

### 示例 2：Credo 复杂度警告

```elixir
# 警告：圈复杂度为 15（最大为 9）

# 不好：将 max_complexity 提高到 20
# 好：重构为管道
def process_order(order, user, opts) do
  order
  |> validate_order()
  |> check_inventory()
  |> apply_discounts(user)
  |> calculate_shipping(opts)
  |> finalize_order()
end
```

### 示例 3：模式匹配警告

```elixir
# 警告：模式永远无法匹配

# 不好：添加到 dialyzer.ignore
# 好：修复模式
# 之前：
def handle_result({:ok, data}), do: process(data)
def handle_result(:ok), do: :ok  # 这永远无法匹配！

# 之后：
def handle_result({:ok, data}), do: process(data)
def handle_result({:error, reason}), do: {:error, reason}
```

## 规则

**如果质量工具抱怨，它试图帮助你写更好的代码。**

**听它的。修复代码。不要沉默信使。**

## 记住

> "每次你添加到忽略文件时，一个生产错误就获得了翅膀。"

> "技术债务不是免费的 - 你每天都要支付利息。"

> "修复代码，而不是工具。"

> "小警告会变成重大错误。'稍后'意味着永远。'不是我的更改'意味着代码库腐烂。"

> "你接触了它，你拥有它。留下比你发现的更好的代码。"
