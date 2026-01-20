---
name: elixir-verification-gate
description: 声称任何东西有效之前的强制验证。运行实际命令，读取实际输出，提供证据。在声称测试通过、构建成功或代码有效时使用。
---

# Elixir 验证门：有证据或没有发生

## 铁律

**永远不要在没有运行和读取输出的情况下声称某些东西有效。**

不是"应该有效"。不是"看起来正确"。不是"我认为它通过了"。

**运行它。读取它。证明它。**

## 绝对要求

在声称以下任何内容之前，你必须提供证据：

### 1. "测试通过"
**必须运行：** `mix test`
**必须读取：** 显示"X tests, 0 failures"的实际测试输出
**必须提供：** 确切的输出或测试计数

```bash
# 必需的证据
$ mix test
..........

Finished in 0.3 seconds (0.1s async, 0.2s sync)
10 tests, 0 failures

# 这是证据 ✓
```

### 2. "代码编译"
**必须运行：** `mix compile --warnings-as-errors`
**必须读取：** 显示"Compiled"或错误消息的输出
**必须提供：** 零警告的确认

```bash
# 必需的证据
$ mix compile --warnings-as-errors
Compiling 5 files (.ex)
Generated my_app app

# 这是证据 ✓
```

### 3. "代码已格式化"
**必须运行：** `mix format --check-formatted`
**必须读取：** 输出或缺少输出
**必须提供：** 确认没有文件需要格式化

```bash
# 必需的证据
$ mix format --check-formatted
# (没有输出意味着所有文件都已格式化)

# 这是证据 ✓
```

### 4. "Credo 通过"
**必须运行：** `mix credo --strict`
**必须读取：** 分析结果
**必须提供：** "no issues found"的确认

```bash
# 必需的证据
$ mix credo --strict
Checking 42 source files...

Please report incorrect results: https://github.com/rrrene/credo/issues

Analysis took 0.3 seconds (0.2s to load, 0.1s running 100 checks on 42 files)
17 mods/funs, found no issues.

# 这是证据 ✓
```

### 5. "Dialyzer 通过"
**必须运行：** `mix dialyzer`
**必须读取：** 类型检查结果
**必须提供：** "done (passed successfully)"消息

```bash
# 必需的证据
$ mix dialyzer
...
Total errors: 0, Skipped: 0, Unnecessary Skips: 0
done (passed successfully)

# 这是证据 ✓
```

### 6. "迁移成功运行"
**必须运行：** `mix ecto.migrate`
**必须读取：** 迁移执行输出
**必须提供：** 迁移完成的确认

```bash
# 必需的证据
$ mix ecto.migrate

15:42:13.456 [info] == Running 20231201150000 MyApp.Repo.Migrations.CreateUsers.change/0 forward

15:42:13.458 [info] create table users

15:42:13.478 [info] == Migrated 20231201150000 in 0.0s

# 这是证据 ✓
```

### 7. "函数正确工作"
**必须运行：** 测试该函数的代码
**必须读取：** 显示它通过的测试输出
**必须提供：** 示例用法或测试代码

```elixir
# 必需的证据
test "create_user/1 with valid attrs creates user" do
  attrs = %{name: "Alice", email: "alice@example.com"}
  assert {:ok, %User{} = user} = Accounts.create_user(attrs)
  assert user.name == "Alice"
  assert user.email == "alice@example.com"
end

# ✓ 测试通过实际运行
```

### 8. "问题已修复"
**必须运行：** 显示问题的命令
**必须读取：** 显示问题不再出现的输出
**必须提供：** 修复前后的对比

```bash
# 必需的证据 - 修复前
$ mix dialyzer
lib/my_app.ex:42:pattern_can_never_match
Total errors: 1

# 应用修复...

# 必需的证据 - 修复后
$ mix dialyzer
Total errors: 0, Skipped: 0, Unnecessary Skips: 0
done (passed successfully)

# 这是证据 ✓
```

## 禁止短语（无证据）

这些短语**禁止**使用，除非附带实际命令输出：

❌ "测试应该通过"
❌ "这应该编译"
❌ "我相信这有效"
❌ "这看起来正确"
❌ "代码似乎在工作"
❌ "我认为这修复了它"
❌ "这应该有效"
❌ "假设测试通过"
❌ "如果你运行测试，它们会通过"
❌ "构建会成功"

**相反，运行命令并报告实际结果。**

## 验证清单

在声称你完成了任何任务之前：

- [ ] 我运行了相关命令（不仅仅是写代码）
- [ ] 我读取了实际输出（没有假设它有效）
- [ ] 我亲眼看到了成功消息
- [ ] 我可以引用确切的输出
- [ ] 所有测试实际通过（我运行了它们）
- [ ] 代码实际编译（我编译了它）
- [ ] 不存在警告（我检查了）
- [ ] 质量检查实际通过（我运行了它们）

**如果你不能用证据检查所有框，你就没有完成。**

## 正确验证的示例

### 示例 1：声称测试通过

**错误：**
```
我已实现了 create_user 函数。测试现在应该通过。
```

**正确：**
```
我已实现了 create_user 函数。运行测试：

$ mix test test/my_app/accounts_test.exs
..........

Finished in 0.2 seconds (0.1s async, 0.1s sync)
10 tests, 0 failures

✓ 所有测试通过。
```

### 示例 2：声称代码编译

**错误：**
```
我已修复了编译错误。现在应该编译。
```

**正确：**
```
我已修复了编译错误。编译中：

$ mix compile --warnings-as-errors
Compiling 1 file (.ex)
Generated my_app app

✓ 编译时零警告。
```

### 示例 3：声称 Dialyzer 满意

**错误：**
```
我添加了 @spec。Dialyzer 不会再抱怨了。
```

**正确：**
```
我添加了 @spec。运行 Dialyzer：

$ mix dialyzer
Finding suitable PLTs
Checking PLT...
...
Total errors: 0, Skipped: 0, Unnecessary Skips: 0
done (passed successfully)

✓ Dialyzer 通过，零错误。
```

### 示例 4：声称迁移有效

**错误：**
```
迁移已准备好，应该运行良好。
```

**正确：**
```
运行迁移：

$ mix ecto.migrate

15:42:13.456 [info] == Running 20231201150000 MyApp.Repo.Migrations.CreateUsers.change/0 forward
15:42:13.458 [info] create table users
15:42:13.478 [info] == Migrated 20231201150000 in 0.0s

✓ 迁移成功执行。
```

## 验证失败时

如果你运行命令并且它失败：

### 不要：
- 无论如何声称它有效
- 说"它应该有效，不确定为什么失败"
- 继续其他任务
- 假设失败是环境问题

### 相反：
1. **完全读取错误消息**
2. **理解什么失败了以及为什么**
3. **修复实际问题**
4. **再次运行命令**
5. **验证它现在通过**
6. **提供成功的证据**

## 验证工作流

**对于你做的每一个更改：**

### 1. 进行更改
```elixir
# 编辑代码
def create_user(attrs) do
  # ... 实现
end
```

### 2. 运行相关测试
```bash
$ mix test test/my_app/accounts_test.exs:42
.

Finished in 0.1 seconds
1 test, 0 failures
```

### 3. 运行完整测试套件
```bash
$ mix test
..........

Finished in 0.3 seconds
10 tests, 0 failures
```

### 4. 运行质量检查
```bash
$ mix format --check-formatted
$ mix credo --strict
$ mix dialyzer
```

### 5. 报告结果
```
✓ 测试通过 (10/10)
✓ 代码已格式化
✓ Credo：无问题
✓ Dialyzer：0 错误
```

**只有这样你才能声称任务完成。**

## 与其他技能的集成

此技能与以下技能配合使用：

- **elixir-tdd-enforcement** - 验证测试失败（RED），验证测试通过（GREEN）
- **elixir-no-shortcuts** - 验证错误已消除（未被抑制）
- **elixir-root-cause-only** - 验证根本原因已修复（不是症状）

**示例 TDD 验证：**
```
1. 编写测试 → 运行 → 看到失败 ← 验证
2. 实现 → 运行 → 看到通过 ← 验证
3. 重构 → 运行 → 看到仍然通过 ← 验证
```

## 特殊情况

### "我无法运行测试，因为..."
**停止。** 修复环境以便你可以运行测试。测试是不可协商的。

### "测试不稳定"
**停止。** 在继续之前修复不稳定性。不稳定的测试 = 破损的测试。

### "Dialyzer 花费太长时间"
**无论如何运行它。** 缓存 PLT。使用 `mix dialyzer --incremental`。没有捷径。

### "我只是在写文档"
**仍然验证。** 运行 `mix docs` 并确认它生成时没有警告。

### "这只是注释更改"
**仍然验证。** 运行 `mix format --check-formatted` 并确保格式保持。

## 错误的理由

### "我不需要运行它，代码显然是正确的"
**错误。** 代码永远不会显然正确。计算机是精确的。运行它。

### "我昨天在本地运行过，仍然有效"
**错误。** 现在运行它，在这个上下文中，使用这些更改。

### "CI 会捕获它"
**错误。** 在推送之前在本地捕获它。CI 是最后的手段，不是主要检查。

### "我确信这有效"
**错误。** 没有证据的信心只是希望。运行。命令。

### "相信我，我知道我在做什么"
**错误。** 信任，但验证。实际上，只是验证。证据 > 信任。

## 跳过验证的后果

**如果你声称某些东西有效而没有运行它：**

1. **它可能不有效** - 墨菲定律适用
2. **你浪费了每个人的时间** - 包括你自己
3. **错误到达生产** - 因为它们没有在本地被捕获
4. **团队速度下降** - 花费时间调试"有效的"代码
5. **你失去信誉** - 没有证据的声称是无意义的

**不运行测试"节省"的 30 秒花费 30 分钟调试。**

## 规则

**有证据或没有发生。**

**如果你没有运行它，你不知道它是否有效。**

**如果你不能引用输出，你没有运行它。**

## 输出模板

验证时，使用此模板：

```markdown
## 验证结果

### 测试
$ mix test
[粘贴实际输出]
✓ 10 tests, 0 failures

### 编译
$ mix compile --warnings-as-errors
[粘贴实际输出]
✓ 零警告

### Credo
$ mix credo --strict
[粘贴实际输出]
✓ 未发现问题

### Dialyzer
$ mix dialyzer
[粘贴实际输出]
✓ 0 错误

## 结论
所有验证步骤通过。任务完成。
```

## 记住

> "代码在你运行它并证明它有效之前不会工作。"

> "假设是所有失败的根源。"

> "如果你不能引用输出，你没有验证它。"

**运行。读取。报告。每一次。**
