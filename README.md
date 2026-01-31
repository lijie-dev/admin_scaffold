# Admin Scaffold - 后台管理脚手架

基于 Phoenix Framework 的后台管理系统脚手架，包含完整的用户认证、权限管理、菜单管理、审计日志、数据导出、文件管理、通知系统和数据统计图表功能。

## 技术栈

- **Phoenix**: 1.8.3
- **Elixir**: ~> 1.15
- **PostgreSQL**: 数据库
- **Phoenix LiveView**: 实时交互 UI
- **Swoosh**: 邮件发送
- **Bandit**: Web 服务器
- **Chart.js**: 数据可视化

## 快速开始

### 1. 安装依赖并设置数据库

```bash
mix setup
```

或者分步执行：

```bash
mix deps.get
mix ecto.create
mix ecto.migrate
```

### 2. 启动服务器

```bash
mix phx.server
```

或者在 IEx 中启动：

```bash
iex -S mix phx.server
```

服务器将在 http://localhost:4000 启动

### 3. 首次使用

1. 访问 http://localhost:4000/users/register 注册账户
2. 输入邮箱和密码完成注册
3. 注册后自动登录，进入仪表板

## 主要功能

### 🎯 仪表板 (`/dashboard`)

登录后的主页面，显示：
- 📊 用户总数统计
- 👥 角色总数统计
- 🔐 权限总数统计
- ⚡ 今日操作数统计
- 📈 最近7天操作趋势图表
- 🔗 快速操作链接（用户、角色、权限、数据统计、个人设置）

### 👤 用户管理 (`/admin/users`)

管理系统中的所有用户：
- **搜索功能**: 按邮箱或 ID 搜索
- **筛选功能**: 按状态、角色筛选
- **批量操作**: 批量删除、批量启用/禁用
- **数据导出**: CSV 格式导出用户数据
- **CRUD**: 创建、编辑、删除用户
- **权限控制**: 基于权限的按钮显示

### 🎭 角色管理 (`/admin/roles`)

管理用户角色：
- **搜索功能**: 按名称或描述搜索
- **批量操作**: 批量删除
- **数据导出**: CSV 格式导出角色数据
- **卡片视图**: 直观的角色展示
- **权限分配**: 为角色分配权限和菜单

### 🔐 权限管理 (`/admin/permissions`)

管理系统权限：
- **搜索功能**: 按名称、标识或描述搜索
- **批量操作**: 批量删除
- **网格布局**: 紧凑的权限展示
- **权限标识**: 用于权限检查的唯一标识符

### 📋 菜单管理 (`/admin/menus`)

管理系统菜单：
- **树形结构**: 支持父子菜单关系
- **排序功能**: 自定义菜单显示顺序
- **状态控制**: 启用/禁用菜单项
- **图标支持**: 自定义菜单图标
- **批量操作**: 批量删除、批量启用/禁用
- **搜索功能**: 按名称或路径搜索

### 🔍 审计日志 (`/admin/audit-logs`)

查看系统操作记录：
- **搜索功能**: 按操作、资源、用户搜索
- **筛选功能**: 按资源类型、操作类型筛选
- **数据导出**: CSV 格式导出审计日志
- **详细信息**: 用户、操作、资源、IP 地址、User Agent
- **自动记录**: 系统自动记录所有关键操作

### ⚙️ 系统设置 (`/admin/settings`)

管理全局配置：
- **网站信息**: 系统名称、描述
- **注册设置**: 允许/禁止新用户注册、是否需要邮箱验证
- **邮件配置**: SMTP 服务器设置
- **维护模式**: 启用/禁用维护模式、只允许管理员访问

### 📁 文件管理 (`/admin/files`)

文件上传和管理：
- **拖拽上传**: 支持拖拽文件上传
- **多文件上传**: 最多同时上传 5 个文件
- **文件类型限制**: JPG, PNG, GIF, PDF, DOC, DOCX, XLS, XLSX
- **上传进度**: 实时显示上传进度
- **文件列表**: 已上传文件展示
- **文件预览**: 图片和文档预览
- **文件删除**: 删除已上传文件

### 🔔 通知中心 (`/notifications`)

查看和管理通知：
- **未读计数**: 实时显示未读通知数量
- **通知类型**: info/success/warning/danger
- **标记已读**: 单个或批量标记为已读
- **删除通知**: 单个或批量删除
- **时间显示**: 相对时间（刚刚、5分钟前、1小时前等）
- **批量操作**: 选择、全选、批量删除、批量标记已读
- **彩色图标**: 根据通知类型显示不同颜色

### 📈 数据统计 (`/admin/charts`)

数据可视化分析：
- **用户增长趋势**: 30 天用户增长折线图
- **角色分布**: 各角色用户数量饼图
- **操作统计**: 7 天操作统计柱状图
- **统计卡片**: 总用户数、活跃用户、总操作数、今日操作数
- **实时更新**: 数据实时更新

## 数据导出

支持以下数据导出为 CSV 格式：

- **用户数据**: `/admin/export/users`
- **角色数据**: `/admin/export/roles`
- **审计日志**: `/admin/export/audit-logs`

导出功能包含：
- 筛选条件支持
- 自动文件命名（带日期）
- UTF-8 编码
- 特殊字符处理

## 权限系统

### 权限级别

1. **路由级权限**: 通过 `RoutePermission` 插件自动检查
2. **按钮级权限**: 使用 `PermissionButton` 组件控制按钮显示
3. **数据权限**: 可扩展的数据范围权限

### 权限标识

- `users.view` - 查看用户列表
- `users.edit` - 编辑用户
- `users.delete` - 删除用户
- `users.export` - 导出用户数据
- `roles.view` - 查看角色列表
- `roles.edit` - 编辑角色
- `roles.delete` - 删除角色
- `roles.export` - 导出角色数据
- `permissions.view` - 查看权限列表
- `permissions.edit` - 编辑权限
- `permissions.delete` - 删除权限
- `menus.view` - 查看菜单列表
- `menus.edit` - 编辑菜单
- `menus.delete` - 删除菜单
- `settings.view` - 查看系统设置
- `settings.edit` - 编辑系统设置
- `audit_logs.view` - 查看审计日志
- `audit_logs.export` - 导出审计日志
- `files.view` - 查看文件管理
- `files.upload` - 上传文件

## 项目结构

```
admin_scaffold/
├── lib/
│   ├── admin_scaffold/
│   │   ├── accounts/          # 用户账户上下文
│   │   │   ├── user.ex        # 用户模型
│   │   │   ├── user_token.ex  # 用户令牌
│   │   │   ├── user_notifier.ex # 用户通知
│   │   │   ├── role.ex       # 角色模型
│   │   │   ├── permission.ex # 权限模型
│   │   │   └── menu.ex       # 菜单模型
│   │   ├── accounts.ex        # 账户业务逻辑
│   │   ├── system.ex         # 系统功能（审计日志、设置、通知）
│   │   └── repo.ex          # 数据库仓库
│   └── admin_scaffold_web/
│       ├── live/
│       │   ├── dashboard_live/     # 仪表板
│       │   ├── user_live/         # 用户管理
│       │   ├── role_live/         # 角色管理
│       │   ├── permission_live/    # 权限管理
│       │   ├── menu_live/         # 菜单管理
│       │   ├── audit_log_live/    # 审计日志
│       │   ├── setting_live/      # 系统设置
│       │   ├── file_upload_live/  # 文件管理
│       │   ├── notification_live/ # 通知中心
│       │   └── chart_live/       # 数据统计
│       ├── components/
│       │   ├── core_components.ex     # 核心组件
│       │   ├── permission_button.ex   # 权限按钮组件
│       │   └── layouts/            # 布局组件
│       ├── controllers/
│       │   ├── export_controller.ex    # 导出控制器
│       │   └── user_session_controller.ex # 会话控制器
│       ├── plugs/
│       │   └── route_permission.ex   # 路由权限验证
│       ├── export.ex                 # 导出功能
│       ├── authorization.ex              # 权限检查
│       └── router.ex                 # 路由配置
├── assets/js/
│   └── app.js                  # Chart.js Hook 集成
├── priv/
│   └── repo/
│       └── migrations/        # 数据库迁移
└── mix.exs                # 项目配置
```

## 路由说明

### 公开路由（无需登录）

- `GET /` - 首页
- `GET /users/register` - 用户注册页面
- `GET /users/log-in` - 用户登录页面
- `POST /users/log-in` - 处理登录请求

### 需要认证的路由

- `GET /dashboard` - 管理仪表板
- `GET /admin/users` - 用户列表
- `GET /admin/users/:id` - 用户详情
- `GET /admin/users/:id/edit` - 编辑用户
- `GET /admin/roles` - 角色列表
- `GET /admin/roles/new` - 新增角色
- `GET /admin/roles/:id/edit` - 编辑角色
- `GET /admin/permissions` - 权限列表
- `GET /admin/permissions/new` - 新增权限
- `GET /admin/permissions/:id/edit` - 编辑权限
- `GET /admin/menus` - 菜单列表
- `GET /admin/menus/new` - 新增菜单
- `GET /admin/menus/:id/edit` - 编辑菜单
- `GET /admin/settings` - 系统设置
- `GET /admin/audit-logs` - 审计日志
- `GET /admin/files` - 文件管理
- `GET /admin/charts` - 数据统计
- `GET /notifications` - 通知中心
- `GET /users/settings` - 个人设置
- `DELETE /users/log-out` - 登出

### 导出路由

- `GET /admin/export/users` - 导出用户 CSV
- `GET /admin/export/roles` - 导出角色 CSV
- `GET /admin/export/audit-logs` - 导出审计日志 CSV

## 开发命令

```bash
# 运行测试
mix test

# 格式化代码
mix format

# 重置数据库
mix ecto.reset

# 生成新的迁移
mix ecto.gen.migration migration_name

# 运行迁移
mix ecto.migrate

# 回滚迁移
mix ecto.rollback
```

## 数据库

项目使用 PostgreSQL 数据库，包含以下表：

- `users` - 用户表
- `users_tokens` - 用户令牌表（用于会话和邮箱确认）
- `roles` - 角色表
- `permissions` - 权限表
- `menus` - 菜单表
- `user_roles` - 用户-角色关联表
- `role_permissions` - 角色-权限关联表
- `role_menus` - 角色-菜单关联表
- `settings` - 系统设置表
- `audit_logs` - 审计日志表
- `notifications` - 通知表

## 设计系统

### Neo-Brutalist Dark 风格

- 独特字体组合 (Syne + Manrope + JetBrains Mono)
- 霓虹色彩方案 (青/粉/黄/紫/橙)
- 动画效果 (淡入、悬停、脉冲、故障文字)
- 响应式布局 (移动端 + 桌面端)

## 注意事项

1. **邮件功能**: 当前 Swoosh 配置了但未设置实际的邮件发送器，邮箱确认功能需要配置邮件服务
2. **生产环境**: 部署到生产环境前，请参考 [Phoenix 部署指南](https://hexdocs.pm/phoenix/deployment.html)
3. **安全性**: 确保在生产环境中设置强密码和安全的 secret_key_base
4. **权限**: 默认创建的角色会拥有部分权限，可根据需求调整
5. **文件上传**: 当前是模拟实现，生产环境需要配置实际的文件存储（如 S3、本地磁盘等）
6. **Chart.js**: 从 CDN 加载 Chart.js 4.4.1 版本

## 版本历史

### Phase 2 (2026-01-31) ✅

**新增功能：**
- ✅ 数据导出功能（CSV 格式）
- ✅ 文件管理模块（拖拽上传、进度显示）
- ✅ 通知系统（未读计数、批量操作）
- ✅ 数据统计图表（用户增长、角色分布、操作统计）

**技术改进：**
- 导出 API 统一
- 通知数据表和索引
- 文件上传 LiveView
- Chart.js 集成
- 数据可视化增强

### Phase 1 (2026-01-30) ✅

**新增功能：**
- ✅ 系统设置模块
- ✅ 搜索和筛选功能
- ✅ 批量操作
- ✅ 权限验证增强

## 了解更多

* Phoenix 官网: https://www.phoenixframework.org/
* Phoenix 指南: https://hexdocs.pm/phoenix/overview.html
* Phoenix 文档: https://hexdocs.pm/phoenix
* Elixir 论坛: https://elixirforum.com/c/phoenix-forum
* Phoenix 源码: https://github.com/phoenixframework/phoenix

## 许可证

MIT
