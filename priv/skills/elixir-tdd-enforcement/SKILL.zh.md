---
name: elixir-tdd-enforcement
description: 任何功能或错误修复都是强制性的 - 首先编写 ExUnit 测试，观察其失败，然后实现。没有例外。在编写任何 Elixir 生产代码之前使用。
---

# Elixir TDD 强制执行：铁律

## 铁律

**没有失败的测试，就没有生产代码**

不是有时候。不是通常。总是。

如果你在失败的测试之前编写生产代码，删除它并重新开始。

## 此技能何时适用

- 实现任何新函数
- 修复任何错误
- 添加任何功能
- 修改任何行为
- 重构任何代码

**如果你在 `lib/` 中更改 `.ex` 文件，此技能是强制性的。**

## 红-绿-重构循环

### 第 1 阶段：红色（编写失败的测试）

1. **编写一个最小的 ExUnit 测试**
   ```elixir
   test "creates user with valid attrs" do
     attrs = %{name: "Alice", email: "alice@example.com"}
     assert {:ok, %User{} = user} = Accounts.create_user(attrs)
     assert user.name == "Alice"
     assert user.email == "alice@example.com"
   end
   ```

2. **运行测试**
   ```bash
   mix test test/my_app/accounts_test.exs:42
   ```

3. **验证它因正确的原因失败**
   - 阅读错误消息
   - 确认它因功能不存在而失败
   - 不是因为语法错误或错误的测试设置

**检查点：如果测试没有失败，删除它并编写不同的测试。**

### 第 2 阶段：绿色（最小实现）

1. **编写最简单的代码来通过测试**
   ```elixir
   def create_user(attrs) do
     %User{}
     |> User.changeset(attrs)
     |> Repo.insert()
   end
   ```

2. **再次运行测试**
   ```bash
   mix test test/my_app/accounts_test.exs:42
   ```

3. **验证它通过**
   - 阅读实际输出
   - 看到绿色点或"1 test, 0 failures"
   - 不要只是假设它有效

**检查点：如果测试没有通过，修复实现（不是测试）。**

### 第 3 阶段：重构（在绿色时改进）

1. **改进代码质量**
   - 提取函数
   - 改进名称
   - 添加模式匹配

2. **在每次更改后运行测试**
   ```bash
   mix test
   ```

3. **保持绿色**
   - 如果测试在重构期间失败，撤销
   - 仅在所有测试通过时重构

**检查点：测试必须在整个重构过程中保持绿色。**

## 验证清单

在声称完成之前，验证：

- [ ] 我在任何实现代码之前编写了测试
- [ ] 我观察了测试因正确的原因失败
- [ ] 我阅读了实际的失败消息
- [ ] 我只实现了足够的代码来通过测试
- [ ] 我再次运行了测试并看到它通过
- [ ] 我阅读了实际的成功消息
- [ ] 所有其他测试仍然通过
- [ ] 我仅在测试为绿色时进行了重构

**如果你不能勾选所有框，你没有遵循 TDD。**

## 常见违规和回应

### 违规："我只是先写代码，然后写测试"
**回应：** 不。删除代码。先写测试。

### 违规："这个函数很简单，我不需要看到它失败"
**回应：** 错误。即使简单的代码也需要失败的测试。写测试，观察失败。

### 违规："我已经知道测试会是什么样子"
**回应：** 无关。无论如何先写它。

### 违规："我同时写了测试和实现"
**回应：** 删除两者。写测试，观察失败，然后实现。

### 违规："测试在第一次运行时通过了"
**回应：** 红旗。测试可能没有测试任何东西。审查测试。

### 违规："我只是在重构，我不需要新测试"
**回应：** 正确 - 但所有现有测试必须保持绿色。

## Elixir 特定的测试模式

### 测试上下文函数
```elixir
# 红色：先写测试
test "list_users/0 returns all users" do
  user1 = fixture(:user)
  user2 = fixture(:user)
  users = Accounts.list_users()
  assert length(users) == 2
  assert user1 in users
  assert user2 in users
end

# 运行测试 → 观察失败（函数不存在）

# 绿色：实现
def list_users do
  Repo.all(User)
end

# 运行测试 → 观察通过
```

### 测试 Changesets
```elixir
# 红色：为验证写测试
test "changeset with invalid email" do
  changeset = User.changeset(%User{}, %{email: "invalid"})
  refute changeset.valid?
  assert %{email: ["invalid format"]} = errors_on(changeset)
end

# 运行测试 → 观察失败

# 绿色：添加验证
def changeset(user, attrs) do
  user
  |> cast(attrs, [:email])
  |> validate_format(:email, ~r/@/)
end
```

### 测试 Phoenix 控制器
```elixir
# 红色：写测试
test "GET /users returns 200", %{conn: conn} do
  conn = get(conn, ~p"/users")
  assert html_response(conn, 200)
end

# 运行测试 → 观察失败（路由不存在）

# 绿色：添加路由和控制器操作
```

## Dialyzer 错误：特殊情况

**如果 Dialyzer 报告错误：**

1. **编写一个测试来执行有问题的代码**
2. **确保测试通过**（证明代码有效）
3. **添加 @spec 来指导 Dialyzer**
4. **运行 `mix dialyzer` 来验证**

**永远不要：**
- 添加到 dialyzer.ignore
- 修改 dialyzer PLT 来抑制
- 注释掉代码

**测试证明它有效。规范帮助 Dialyzer 理解。**

## Credo 警告：特殊情况

**如果 Credo 报告警告：**

1. **理解为什么它在警告**
2. **修复实际问题**（复杂性、风格等）
3. **运行 `mix credo` 来验证**

**永远不要：**
- 添加到 .credo.exs 禁用列表
- 使用内联 `# credo:disable-for-this-file`
- 忽略警告

**Credo 在帮助你写更好的代码。听它的。**

## 纪律

TDD 一开始感觉很慢。那是因为你习惯于：
- 快速编写代码（然后调试数小时）
- 跳过测试（然后在生产中破坏东西）
- 猜测它是否有效（然后发现它没有）

TDD 实际上更快，因为：
- 测试立即捕获错误
- 你确切知道要实现什么
- 重构是安全的
- 代码第一次就有效

## 强制执行

**在编写任何 Elixir 生产代码之前，问自己：**

1. "我为此写了一个失败的测试吗？"
2. "我真的运行了测试并看到它失败了吗？"
3. "我知道为什么它失败了吗？"

**如果任何答案是否 → 先写测试。**

## 记住

> "在第一次运行时通过的测试可能没有测试任何东西。"

> "没有失败测试的代码是猜测驱动的开发。"

> "TDD 很慢。调试未测试的代码更慢。"

## 规则

**红 → 绿 → 重构**

**不是 绿 → 红 → "哎呀"**

**不是 写 → 祈祷 → 调试**

**红 → 绿 → 重构**

每一次。单一的。时间。
