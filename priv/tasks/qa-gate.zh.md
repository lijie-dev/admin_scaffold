# 任务：质量门控验证

**目的**：确保代码在合并前满足所有质量标准

**代理**：elixir-qa

**时长**：30 分钟 - 1 小时

## 概述

质量门控强制执行标准并在代码到达生产环境前捕获问题。此任务验证测试覆盖率、代码质量、类型安全性和格式化。

## 质量门控

### 门控 1：测试套件

**命令**：`mix test`

**要求：**
- ✅ 所有测试必须通过（100% 通过率）
- ✅ 没有待处理/跳过的测试（无正当理由）
- ✅ 新代码的测试覆盖率 ≥ 80%
- ✅ 没有测试警告或弃用警告

**常见失败：**
- 测试中的 N+1 查询警告
- 不稳定的测试（竞态条件）
- 缺少测试数据工厂
- 修改全局状态的测试

**修复策略：**
```elixir
# N+1 查询修复
# 不好：关联访问中的 N+1 查询
users = Repo.all(User)
Enum.map(users, fn user -> user.posts end)  # 为每个用户查询！

# 好：预加载关联
users = Repo.all(User) |> Repo.preload(:posts)
Enum.map(users, fn user -> user.posts end)  # 已加载

# 不稳定测试修复
# 不好：异步操作中的竞态条件
test "processes message" do
  start_processor()
  send_message(msg)
  assert message_processed?()  # 可能因时序失败
end

# 好：使用适当的同步
test "processes message" do
  start_processor()
  send_message(msg)
  assert_receive {:message_processed, ^msg}, 1000
end
```

### 门控 2：静态分析（Credo）

**命令**：`mix credo --strict`

**要求：**
- ✅ 没有 Credo 问题（警告或错误）
- ✅ 代码遵循 Elixir 风格指南
- ✅ 没有检测到代码异味
- ✅ 圈复杂度在限制范围内

**常见问题：**
```elixir
# Credo：避免在管道中使用 if/else
# 不好
result =
  data
  |> process()
  |> if do
    transform()
  else
    default()
  end

# 好
result =
  data
  |> process()
  |> then(fn processed ->
    if condition?(processed), do: transform(processed), else: default(processed)
  end)

# Credo：单条件时优先使用 case 而不是 cond
# 不好
cond do
  x > 10 -> :large
  true -> :small
end

# 好
if x > 10, do: :large, else: :small
```

### 门控 3：类型安全（Dialyzer）

**命令**：`mix dialyzer`

**要求：**
- ✅ 没有 Dialyzer 警告
- ✅ 所有公共函数都有类型规范
- ✅ 没有检测到死代码
- ✅ 没有不可达的代码路径

**常见警告：**
```elixir
# Dialyzer：返回类型不匹配
# 不好
@spec get_user(integer()) :: User.t()
def get_user(id) do
  Repo.get(User, id)  # 返回 User.t() | nil，不是 User.t()！
end

# 好
@spec get_user(integer()) :: User.t() | nil
def get_user(id) do
  Repo.get(User, id)
end

# 或使用 bang 版本
@spec get_user!(integer()) :: User.t()
def get_user!(id) do
  Repo.get!(User, id)  # 未找到时抛出异常
end

# Dialyzer：在错误类型上进行模式匹配
# 不好
@spec process({:ok, String.t()}) :: String.t()
def process({:ok, value}) when is_binary(value) do
  # 守卫是冗余的 - 规范已经说它是 String.t()
  String.upcase(value)
end

# 好
@spec process({:ok, String.t()}) :: String.t()
def process({:ok, value}) do
  String.upcase(value)
end
```

### 门控 4：代码格式化

**命令**：`mix format --check-formatted`

**要求：**
- ✅ 所有代码格式正确
- ✅ 没有检测到格式化差异

**修复**：运行 `mix format` 并提交更改

### 门控 5：编译警告

**命令**：`mix compile --warnings-as-errors`

**要求：**
- ✅ 没有编译器警告
- ✅ 没有未使用的变量/函数
- ✅ 没有模糊的别名

**常见警告：**
```elixir
# 警告：未使用的变量
# 不好
def process(data, _unused) do
  transform(data)
end

# 好：如果故意未使用，则以下划线为前缀
def process(data, _opts) do
  transform(data)
end

# 警告：未定义的函数
# 不好 - 函数名中的拼写错误
def handle_event("save", params, socket) do
  save_data(parms)  # 拼写错误：parms 而不是 params
end

# 好
def handle_event("save", params, socket) do
  save_data(params)
end
```

## 自动化质量检查

在 `mix.exs` 中创建 `mix precommit` 别名：

```elixir
defp aliases do
  [
    # ... 其他别名
    precommit: [
      "format",
      "test",
      "credo --strict",
      "dialyzer"
    ]
  ]
end
```

在提交前运行：
```bash
mix precommit
```

## 手动代码审查清单

### 架构与设计
- [ ] 遵循代码库中的现有模式
- [ ] 没有上帝模块（> 500 行）
- [ ] 适当的关注点分离
- [ ] 上下文边界得到尊重
- [ ] 没有循环依赖

### Phoenix 模式
- [ ] 业务逻辑在上下文中，不在控制器中
- [ ] 控制器精简（< 100 行）
- [ ] Repo 调用仅在上下文中
- [ ] 正确使用 LiveView 生命周期
- [ ] 为集合使用 Streams（不是 assigns）

### Ecto 模式
- [ ] 需要时预加载关联
- [ ] 在外键和查询字段上建立索引
- [ ] 在模式和迁移中都有约束
- [ ] 没有 N+1 查询
- [ ] 多步骤操作的适当事务使用

### LiveView 模式
- [ ] 所有表单都使用 `to_form/1`
- [ ] 使用来自 core_components 的 `<.input>` 组件
- [ ] Streams 有 `phx-update="stream"` 和适当的 ID
- [ ] 仅在 `connected?(socket)` 时订阅 PubSub
- [ ] 为 streams 处理空状态
- [ ] HEEx 中没有 `else if`（改用 `cond`）

### 错误处理
- [ ] 返回 `{:ok, result}` 或 `{:error, reason}` 元组
- [ ] 错误处理得当
- [ ] 用户友好的错误消息
- [ ] 正常流程中没有未处理的异常
- [ ] 适当的调试日志记录

### 安全性
- [ ] 所有操作都有授权检查
- [ ] 在 changesets 中进行输入验证
- [ ] 没有 SQL 注入漏洞
- [ ] 启用 CSRF 保护
- [ ] 代码中没有秘密

### 性能
- [ ] 没有 N+1 查询
- [ ] 数据库上有适当的索引
- [ ] 大型数据集的分页
- [ ] 大型集合使用 Streams
- [ ] 模板中没有昂贵的计算

### 测试
- [ ] 上下文函数的单元测试
- [ ] UI 交互的 LiveView 测试
- [ ] 边界情况已覆盖
- [ ] 错误路径已测试
- [ ] 测试使用适当的工厂/fixtures

## 质量门控报告

运行所有门控后，创建摘要：

```markdown
# 质量门控报告 - STORY-123

**日期**：2024-01-15
**分支**：feature/add-search
**开发者**：elixir-dev

## 结果

| 门控 | 状态 | 详情 |
|------|--------|---------|
| 测试 | ✅ 通过 | 42 个测试，0 个失败，94% 覆盖率 |
| Credo | ✅ 通过 | 未发现问题 |
| Dialyzer | ✅ 通过 | 没有警告 |
| 格式 | ✅ 通过 | 所有文件已格式化 |
| 编译 | ✅ 通过 | 没有警告 |

## 手动审查

- [x] 架构遵循现有模式
- [x] 没有引入 N+1 查询
- [x] 适当的错误处理
- [x] 安全检查到位
- [x] 性能可接受

## 建议

无 - 准备合并！

## 运行的命令

```bash
mix precommit
# 所有检查通过 ✅
```
```

## 阻止问题

如果任何门控失败，**不要合并**。常见阻止因素：

### ❌ 测试失败
```bash
# 输出
1) test creates user with valid data (MyApp.AccountsTest)
   Expected: {:ok, %User{}}
   Got: {:error, #Ecto.Changeset<...>}
```

**操作**：修复测试或实现，确保所有测试通过

### ❌ Credo 问题
```bash
# 输出
┃ [R] ↗ Avoid negated conditions in unless blocks.
┃     lib/my_app/accounts.ex:45
```

**操作**：重构代码以解决问题

### ❌ Dialyzer 警告
```bash
# 输出
lib/my_app/accounts.ex:23:callback_missing
Function get_user/1 has no @spec typespec.
```

**操作**：添加适当的类型规范

### ❌ 格式化问题
```bash
# 输出
** (Mix) mix format failed due to --check-formatted.
The following files are not formatted:
  * lib/my_app/accounts.ex
```

**操作**：运行 `mix format` 并提交

## 紧急绕过

在极少数情况下，质量门控可能需要绕过（生产热修复）。记录原因：

```markdown
# 质量门控绕过

**故事**：STORY-456
**日期**：2024-01-15
**原因**：关键生产问题 - 支付处理中断
**绕过**：Dialyzer（新 OTP 行为的已知假阳性）
**计划**：将在后续 STORY-457 中修复 Dialyzer 警告
**批准者**：技术主管
```

## 与 Git 钩子集成

质量门控可以通过 pre-commit 钩子自动运行：

```bash
#!/bin/sh
# .git/hooks/pre-commit

echo "Running quality gates..."

# 运行 mix precommit
mix precommit
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
  echo "❌ Quality gates failed! Fix issues before committing."
  exit 1
fi

echo "✅ Quality gates passed!"
exit 0
```

## 质量指标仪表板

跟踪一段时间内的质量：

```elixir
# 要跟踪的质量指标
- 测试覆盖率趋势（应该增加）
- Credo 问题计数（应该为 0）
- Dialyzer 警告（应该为 0）
- 平均圈复杂度（应该 < 10）
- 每个模块的代码行数（应该 < 500）
- N+1 查询数量（应该为 0）
```

## 后续步骤

通过所有质量门控后：
1. 创建拉取请求
2. 请求代码审查
3. 处理审查反馈
4. 合并到主分支
5. 在生产中监控

## 资源

- [Credo 文档](https://hexdocs.pm/credo)
- [Dialyzer 用户指南](https://www.erlang.org/doc/man/dialyzer.html)
- [ExUnit 文档](https://hexdocs.pm/ex_unit)
- [Phoenix 测试指南](https://hexdocs.pm/phoenix/testing.html)
