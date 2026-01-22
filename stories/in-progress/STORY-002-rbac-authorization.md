# STORY-002: 实现 RBAC 权限检查机制

## 用户故事
作为系统管理员
我想要基于角色的权限检查自动应用到所有受保护的操作
以便确保用户只能访问他们被授权的功能

## 背景
当前系统已经有了 RBAC 的数据结构（roles, permissions, menus），但缺少实际的权限检查机制：
- LiveView 中没有权限验证
- 没有统一的权限检查函数
- 菜单显示没有基于权限过滤
- 操作按钮（编辑、删除）没有权限控制

## 任务
- [ ] 在 Accounts context 中创建权限检查函数
  - `has_permission?(user, permission_slug)`
  - `get_user_permissions(user_id)`
  - `can_access_menu?(user, menu_path)`
- [ ] 创建 LiveView 权限检查 plug
- [ ] 为受保护的 LiveView 添加权限验证
- [ ] 实现基于权限的菜单过滤
- [ ] 在 UI 中隐藏未授权的操作按钮
- [ ] 添加权限缓存机制（避免重复查询）
- [ ] 编写权限检查的集成测试

## 验收标准
- [ ] 未授权用户无法访问受保护的 LiveView 页面
- [ ] 菜单只显示用户有权限访问的项目
- [ ] 操作按钮根据权限动态显示/隐藏
- [ ] 权限检查性能良好（使用缓存）
- [ ] 权限被拒绝时显示友好的错误消息
- [ ] 所有权限检查都有测试覆盖

## 技术说明
创建权限检查模块：
```elixir
defmodule AdminScaffoldWeb.Authorization do
  def has_permission?(user, permission_slug) do
    # 检查用户的角色是否包含该权限
  end

  def require_permission(socket, permission_slug) do
    # LiveView 中使用的权限检查
  end
end
```

在 LiveView 中使用：
```elixir
def mount(_params, _session, socket) do
  socket = require_permission(socket, "users.manage")
  {:ok, socket}
end
```

## 依赖关系
- 依赖 STORY-001（需要稳定的 Schema 层）

## 测试策略
- 单元测试：测试权限检查函数的各种场景
- 集成测试：测试 LiveView 权限验证
- 端到端测试：测试完整的用户权限流程

## 完成定义
- [ ] 所有任务已完成
- [ ] 所有验收标准已满足
- [ ] 测试已编写并通过
- [ ] 代码已审查
- [ ] 文档已更新（包括权限配置指南）
