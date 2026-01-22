# STORY-001: 改进 Schema 验证和数据完整性

## 用户故事
作为系统管理员
我想要确保所有数据输入都经过严格验证
以便防止无效数据进入数据库并保证数据质量

## 背景
当前的 Schema 层（Role, Permission, Menu）缺少完善的验证规则：
- 字段长度没有限制
- status 字段使用 integer 而不是 enum
- Permission.slug 缺少格式验证
- 缺少业务规则验证

这可能导致数据质量问题和潜在的安全风险。

## 任务
- [ ] 为 Role schema 添加字段长度验证（name: 1-100, description: 0-500）
- [ ] 将 Role.status 从 integer 改为 Ecto.Enum（:active, :inactive）
- [ ] 为 Permission.slug 添加格式验证（只允许小写字母、数字和连字符）
- [ ] 为 Permission 添加字段长度验证（name: 1-100, slug: 1-100）
- [ ] 为 Menu schema 添加完整的验证规则
- [ ] 更新相关的 migration 文件
- [ ] 更新 Accounts context 中的相关函数
- [ ] 为所有 changeset 编写测试

## 验收标准
- [ ] Role.status 使用 Ecto.Enum，只接受 :active 和 :inactive
- [ ] 所有字符串字段都有长度限制
- [ ] Permission.slug 只接受有效的 slug 格式（如 "user-management"）
- [ ] 无效数据被 changeset 拒绝并返回清晰的错误消息
- [ ] 所有现有测试仍然通过
- [ ] 新增的验证规则有对应的测试覆盖

## 技术说明
使用 Ecto.Enum 定义 status：
```elixir
schema "roles" do
  field :status, Ecto.Enum, values: [:active, :inactive], default: :active
end
```

使用正则表达式验证 slug 格式：
```elixir
validate_format(:slug, ~r/^[a-z0-9]+(?:-[a-z0-9]+)*$/)
```

## 依赖关系
无

## 测试策略
- 单元测试：测试每个 changeset 的验证规则
- 边界测试：测试最小/最大长度
- 格式测试：测试 slug 的各种有效和无效格式

## 完成定义
- [ ] 所有任务已完成
- [ ] 所有验收标准已满足
- [ ] 测试已编写并通过（覆盖率 > 90%）
- [ ] 代码已格式化（mix format）
- [ ] Credo 检查通过
- [ ] 文档已更新
