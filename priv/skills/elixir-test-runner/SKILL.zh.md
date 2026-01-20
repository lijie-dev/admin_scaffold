---
name: elixir-test-runner
description: 使用智能过滤、调试选项和适当的错误报告运行 ExUnit 测试。在运行测试、调试失败或验证特定测试用例时使用。
allowed-tools: Bash, Read, Grep
---

# Elixir 测试运行器

此技能帮助你高效地运行 ExUnit 测试，具有适当的过滤、调试和错误分析功能。

## 何时使用

- 运行完整测试套件
- 测试特定文件或测试
- 调试测试失败
- 运行带覆盖率的测试
- 在不同环境中测试

## 基本测试执行

### 运行所有测试
```bash
mix test
```

### 运行特定测试文件
```bash
mix test test/my_app/accounts_test.exs
```

### 按行号运行特定测试
```bash
mix test test/my_app/accounts_test.exs:42
```

### 运行匹配模式的测试
```bash
# 运行名称中包含 "user" 的所有测试
mix test --only user
```

## 测试过滤

### 按标签过滤
```elixir
# 在测试文件中
@tag :integration
test "complex integration test" do
  # ...
end
```

```bash
# 仅运行集成测试
mix test --only integration

# 排除慢速测试
mix test --exclude slow

# 运行除集成测试外的所有内容
mix test --exclude integration
```

### 按模块模式过滤
```bash
# 运行所有控制器测试
mix test test/**/controllers/*_test.exs

# 运行所有 LiveView 测试
mix test test/**/*_live_test.exs
```

### Umbrella 应用过滤
```bash
# 运行特定应用的测试
mix test apps/my_app/test

# 运行所有 umbrella 测试
mix test --only apps
```

## 调试选项

### 使用追踪（详细输出）
```bash
mix test --trace
```
显示每个测试运行时的情况 - 对于挂起的测试很有用。

### 使用详细失败信息
```bash
mix test --max-failures 1
```
在第一次失败后停止，以加快调试速度。

### 使用测试种子
```bash
# 测试默认以随机顺序运行
# 要重现特定顺序：
mix test --seed 123456

# 在输出中查看种子：
# "Randomized with seed 123456"
```

### 使用 IEx 进行调试
```bash
# 在测试代码中添加 IEx.pry()
mix test --trace
```

## 测试输出控制

### 仅显示失败
```bash
mix test --failed
```
重新运行仅之前失败的测试。

### 陈旧测试
```bash
mix test --stale
```
仅运行已更改文件的测试。

### 带覆盖率
```bash
mix test --cover
```
在 `cover/` 目录中生成覆盖率报告。

### 安静模式
```bash
mix test --quiet
```
输出较少详细信息。

## 测试环境

### 标准测试运行
```bash
mix test
```
自动使用 MIX_ENV=test。

### 使用数据库重置
```bash
mix ecto.reset && mix test
```
每次运行都使用新数据库。

### CI 模式
```bash
# 确保警告失败，运行覆盖率
mix test --warnings-as-errors --cover
```

## 常见测试模式

### 测试套件组织

**单元测试**（快速、隔离）：
```bash
mix test test/my_app/accounts/user_test.exs
```

**集成测试**（较慢、带数据库）：
```bash
mix test --only integration
```

**控制器测试**：
```bash
mix test test/my_app_web/controllers/
```

**LiveView 测试**：
```bash
mix test test/my_app_web/live/
```

### 并行测试

```elixir
# 在 test_helper.exs 中 - 已是默认值
ExUnit.start()

# 在 DataCase 中
use MyApp.DataCase, async: true  # 并行执行
```

```bash
# 使用更多核心运行
mix test --max-cases 8
```

## 分析测试失败

### 仔细阅读失败输出

失败示例：
```
1) test creates user with valid attrs (MyApp.AccountsTest)
   test/my_app/accounts_test.exs:42
   ** (RuntimeError) Database not started
```

**要检查的内容：**
1. 测试名称："creates user with valid attrs"
2. 模块：MyApp.AccountsTest
3. 文件和行号：test/my_app/accounts_test.exs:42
4. 错误：Database not started

### 常见失败模式

**数据库未启动：**
```bash
# 启动数据库
mix ecto.create
MIX_ENV=test mix ecto.migrate
```

**异步测试冲突：**
```elixir
# 如果测试冲突，改为同步
use MyApp.DataCase, async: false
```

**缺少设置：**
```elixir
# 检查缺少的设置块
setup do
  :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
end
```

**工厂/Fixture 问题：**
```bash
# 验证工厂数据有效
mix test test/support/fixtures.exs --trace
```

## 性能优化

### 识别慢速测试
```bash
# 使用计时运行
mix test --trace | grep -E "^\s+test.*\([0-9]+\.[0-9]+s\)"
```

### 分析测试套件
```bash
# 使用分析
mix test --profile
```

### 并行执行
```elixir
# 为快速单元测试启用异步
use MyApp.DataCase, async: true

# 为集成测试禁用
use MyApp.DataCase, async: false
```

## 测试覆盖率

### 生成覆盖率报告
```bash
mix test --cover
```

查看报告：`cover/excoveralls.html`

### 覆盖率配置
```elixir
# 在 mix.exs 中
def project do
  [
    test_coverage: [tool: ExCoveralls],
    preferred_cli_env: [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test
    ]
  ]
end
```

### 使用 ExCoveralls
```bash
# HTML 报告
mix coveralls.html

# 详细的控制台报告
mix coveralls.detail

# 检查覆盖率阈值
mix coveralls --min-coverage 80
```

## CI/CD 集成

### GitHub Actions
```yaml
- name: Run tests
  run: mix test --warnings-as-errors --cover
```

### GitLab CI
```yaml
test:
  script:
    - mix ecto.create
    - mix ecto.migrate
    - mix test --cover
```

### Pre-commit 钩子
```bash
#!/bin/bash
# .git/hooks/pre-commit
mix test --failed || exit 1
```

## 故障排除

### 测试挂起
```bash
# 使用 --trace 查看哪个测试挂起
mix test --trace

# 查找：
# - 数据库连接问题
# - 无限循环
# - 缺少冲突测试的 async: false
```

### 测试在本地通过，在 CI 中失败
**常见原因：**
1. 缺少 MIX_ENV=test
2. 数据库未创建
3. 依赖项未获取
4. 不同的 Elixir/OTP 版本
5. 异步测试冲突

**调试：**
```bash
# 在本地重现 CI 环境
MIX_ENV=test mix do deps.get, ecto.create, ecto.migrate, test
```

### 不稳定的测试
```bash
# 多次运行同一测试
mix test test/my_app/accounts_test.exs:42 --trace
mix test test/my_app/accounts_test.exs:42 --trace
mix test test/my_app/accounts_test.exs:42 --trace

# 检查：
# - 时间相关的逻辑
# - 没有种子的随机数据
# - 异步冲突
# - 外部依赖
```

### 内存问题
```bash
# 使用更多内存运行
elixir --erl "+hms 4294967296" -S mix test
```

## 最佳实践

1. **在开发期间频繁运行测试**
2. **使用 --stale** 获得快速反馈循环
3. **标记慢速测试**并在开发期间排除
4. **立即修复失败** - 不要累积
5. **调试时使用 --trace**
6. **提交前运行完整套件**
7. **检查覆盖率**以获得关键代码路径
8. **保持测试快速** - 模拟外部服务
9. **使用工厂**获得一致的测试数据
10. **在 CI 中运行**以捕获环境问题

## 快速参考

```bash
# 开发工作流
mix test --stale                    # 快速反馈
mix test test/my_app/file_test.exs # 特定文件
mix test --failed                   # 重新运行失败

# 调试
mix test --trace                    # 查看每个测试
mix test --max-failures 1          # 在第一次失败时停止
mix test --seed 123456             # 重现顺序

# 覆盖率
mix test --cover                    # 基本覆盖率
mix coveralls.html                  # 详细 HTML

# 过滤
mix test --only integration        # 标记的测试
mix test --exclude slow            # 排除标记的

# CI/CD
mix test --warnings-as-errors --cover
```
