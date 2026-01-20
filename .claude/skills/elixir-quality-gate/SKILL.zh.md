---
name: elixir-quality-gate
description: 运行全面的 Elixir 质量检查（格式化、credo、dialyzer、测试），具有适当的错误处理和报告。在验证代码质量、提交前或准备部署时使用。
allowed-tools: Bash, Read, Grep
---

# Elixir 质量门禁

此技能在 Elixir/Phoenix 项目上运行全面的质量检查，遵循最佳实践。

## 何时使用

- 创建提交前
- 实现新功能后
- 合并拉取请求前
- 准备部署时
- 代码审查期间

## 执行的质量检查

### 1. 代码格式化
```bash
mix format --check-formatted
```
- 验证所有文件格式正确
- 如果发现格式问题则快速失败
- 显示哪些文件需要格式化

### 2. 编译
```bash
mix compile --warnings-as-errors
```
- 确保干净编译
- 将警告视为错误
- 捕获未使用的变量、已弃用的函数

### 3. 静态分析（Credo）
```bash
mix credo --strict
```
- 运行严格的代码质量检查
- 检查一致性、设计问题、可读性
- 报告重构机会

### 4. 类型检查（Dialyzer）
```bash
mix dialyzer
```
- 执行静态类型分析
- 如果需要则构建 PLT（持久查找表）
- 首次运行需要 1-2 分钟，后续运行速度快
- 捕获类型错误和不一致

### 5. 测试套件
```bash
mix test
```
- 运行完整测试套件
- 如果配置则报告覆盖率
- 显示失败和待处理的测试

## 使用模式

### 完整质量门禁（推荐）
按顺序运行所有检查：
```bash
mix format --check-formatted && \
mix compile --warnings-as-errors && \
mix credo --strict && \
mix dialyzer && \
mix test
```

### 快速检查（提交前）
如果项目有 precommit 别名：
```bash
mix precommit
```

### 单个检查
迭代时运行特定检查：
```bash
# 仅格式化
mix format

# 仅测试
mix test

# 特定测试文件
mix test test/my_app/accounts_test.exs

# 仅 credo
mix credo --strict
```

## 错误处理

**格式化失败：**
- 读取输出以查看哪些文件需要格式化
- 运行 `mix format` 自动修复
- 重新运行检查

**编译警告：**
- 仔细阅读警告
- 常见问题：未使用的变量（前缀为 _）、已弃用的函数
- 在继续前修复警告

**Credo 问题：**
- 审查建议的改进
- 重构机会是可选的但推荐
- 应该解决设计和一致性问题

**Dialyzer 错误：**
- 首次运行构建 PLT（需要时间，这是正常的）
- 类型错误表示潜在的运行时错误
- 使用 @spec 注解指导 Dialyzer

**测试失败：**
- 仔细阅读失败消息
- 隔离运行失败的测试：`mix test test/path/to/test.exs:LINE`
- 在继续前修复失败

## 最佳实践

1. **在推送前本地运行** - 尽早捕获问题
2. **首先修复格式化** - 这是最快的修复
3. **不要忽视警告** - 它们通常表示真实问题
4. **保持 PLT 缓存** - 将 `priv/plts/` 添加到 .gitignore
5. **在 PR 前运行完整套件** - 不要仅依赖 CI

## 环境变量

```bash
# 在测试环境中运行
MIX_ENV=test mix dialyzer

# 如果在本地构建 PLT 耗时过长，则跳过 dialyzer
mix format && mix compile --warnings-as-errors && mix credo --strict && mix test
```

## 退出代码

- 0：所有检查通过
- 非零：至少一个检查失败（使用 && 在第一个失败处停止）

## 与 Git 钩子集成

如果使用 BMAD git 钩子，这些检查会自动在以下情况运行：
- pre-commit：完整质量门禁
- pre-push：快速验证

## 故障排除

**PLT 构建失败：**
```bash
# 清理并重建
rm -rf _build priv/plts
mix deps.get
mix dialyzer --plt
```

**测试在 CI 中失败但在本地通过：**
- 检查 MIX_ENV（应为 test）
- 验证数据库已创建：`MIX_ENV=test mix ecto.create`
- 检查异步测试冲突

**Credo 报告过多问题：**
- 从格式化和编译开始
- 首先修复高优先级问题
- 考虑配置 .credo.exs 以匹配团队偏好
