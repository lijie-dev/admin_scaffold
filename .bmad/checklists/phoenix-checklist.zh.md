# Phoenix 最佳实践检查清单

在实现 Phoenix 功能时使用此检查清单，以确保您遵循既定的模式和最佳实践。

## Context 设计

### 有界上下文
- [ ] Context 具有清晰的单一职责
- [ ] Context 名称代表一个领域概念（Accounts、Billing、Content，而不是 "Helpers"）
- [ ] 公共 API 最小化且定义明确
- [ ] 内部/私有函数清晰标记
- [ ] Context 之间没有循环依赖

### 函数
- [ ] 公共函数记录其返回类型
- [ ] 函数返回 `{:ok, result}` 或 `{:error, reason}` 元组
- [ ] Bang 函数 (!) 为预期错误抛出异常
- [ ] 查询函数没有副作用
- [ ] 变更操作清晰指示它们修改数据

## Controllers

### 结构
- [ ] Controllers 精简 - 业务逻辑在 contexts 中
- [ ] 每个资源每个 HTTP 动词一个 action
- [ ] 通过 action fallback controller 处理错误
- [ ] 返回正确的状态码（200、201、204、400、404 等）

### JSON APIs
- [ ] 在 changeset 中进行请求验证，而不是在 controller 中
- [ ] 一致的 JSON 响应格式
- [ ] 响应中有适当的错误消息
- [ ] 如果是公共 API，需要 API 版本控制

### Web Controllers
- [ ] Flash 消息用于用户反馈
- [ ] POST/PUT/DELETE 后进行重定向
- [ ] 清晰显示表单错误
- [ ] 启用 CSRF 保护

## Router

### 路由
- [ ] RESTful 路由遵循约定
- [ ] 嵌套路由限制在 1-2 级
- [ ] 在模板中使用命名路由（`~p"/users/#{user}"`）
- [ ] 路由按关注点/context 组织
- [ ] API 路由使用 `/api` 前缀

### Pipelines
- [ ] 身份验证要求在 router 中，而不是在单个 actions 中
- [ ] Pipelines 由小的、专注的 plugs 组成
- [ ] Browser pipeline 包括 CSRF、fetch session/flash
- [ ] API pipeline 最小化（无 CSRF、session）

## 模板和组件

### HEEx 模板
- [ ] 使用来自 core_components 的函数组件（`<.component>`）
- [ ] 最小化模板中的逻辑
- [ ] 将可重用的标记提取到组件中
- [ ] 没有内联样式（使用 Tailwind 类）
- [ ] 可访问性属性（aria-*、alt、label）

### 组件
- [ ] 组件是纯函数
- [ ] 使用 Slots 实现灵活的布局
- [ ] 使用 attr/3 验证 Props
- [ ] 可在 contexts 之间重用
- [ ] 有良好的文档和示例

## 安全性

### 身份验证和授权
- [ ] 身份验证在 plug pipeline 中
- [ ] 每个 action 中都有授权检查
- [ ] 无法访问其他用户的数据
- [ ] 适当的会话管理
- [ ] 安全的密码哈希（bcrypt）

### 输入验证
- [ ] 所有用户输入都经过验证
- [ ] Changeset 验证全面
- [ ] SQL 注入已防止（使用 Ecto 查询）
- [ ] XSS 已防止（HEEx 自动转义）
- [ ] 启用 CSRF 保护

### 秘密
- [ ] 源代码中没有秘密
- [ ] 配置使用环境变量
- [ ] Secret key base 正确设置
- [ ] API 密钥未提交

## 性能

### 数据库查询
- [ ] 没有 N+1 查询（使用 preload 或 join）
- [ ] 外键上有索引
- [ ] 经常查询的字段上有索引
- [ ] 大结果集进行分页
- [ ] 使用 `select` 限制加载的字段

### 缓存
- [ ] 昂贵的计算已缓存
- [ ] 缓存失效策略清晰
- [ ] APIs 使用 ETag/条件请求
- [ ] 静态资源已指纹识别

## 错误处理

### 面向用户的错误
- [ ] 友好的错误消息
- [ ] 自定义 404 页面
- [ ] 自定义 500 页面
- [ ] 配置错误跟踪（Sentry、AppSignal 等）

### 开发者错误
- [ ] 日志中有有用的错误消息
- [ ] 开发中有堆栈跟踪
- [ ] 错误消息中没有敏感数据
- [ ] 监控错误率

## 测试

### 覆盖率
- [ ] 所有公共 context 函数都经过测试
- [ ] 所有 controller actions 都经过测试
- [ ] 覆盖了快乐路径
- [ ] 覆盖了错误情况
- [ ] 识别并测试了边界情况

### 测试质量
- [ ] 测试可读且易于维护
- [ ] 为测试数据提供工厂/fixture 函数
- [ ] 测试隔离（无共享状态）
- [ ] 快速测试套件（完整运行 < 30 秒）
- [ ] 尽可能使用异步测试

## 文档

### 代码文档
- [ ] 所有公共模块都有 @moduledoc
- [ ] 所有公共函数都有 @doc
- [ ] @doc 块中有示例
- [ ] 复杂逻辑用注释解释
- [ ] README 保持最新

### API 文档
- [ ] API 端点已记录（Swagger/OpenAPI）
- [ ] 提供了请求/响应示例
- [ ] 记录了错误响应
- [ ] 记录了速率限制

## 配置

### 环境
- [ ] 开发配置用于本地工作
- [ ] 测试配置隔离
- [ ] 生产配置安全
- [ ] 发布中的运行时配置

### 依赖项
- [ ] 最小化依赖项
- [ ] 依赖项保持最新
- [ ] 检查安全漏洞（`mix deps.audit`）
- [ ] 移除未使用的依赖项

## 部署

### 发布
- [ ] Mix release 已配置
- [ ] 迁移自动运行或已记录
- [ ] 健康检查端点（`/health`）
- [ ] 优雅关闭处理

### 监控
- [ ] 收集应用程序指标
- [ ] 监控错误率
- [ ] 跟踪性能指标
- [ ] 日志聚合且可搜索

## Phoenix 特定模式

### Contexts
✅ **好的做法：**
```elixir
# 公共 API
def get_user!(id), do: Repo.get!(User, id)
def list_users, do: Repo.all(User)
def create_user(attrs), do: %User{} |> User.changeset(attrs) |> Repo.insert()

# 所有 Repo 调用都在 context 内部
```

❌ **不好的做法：**
```elixir
# Controller 直接调用 Repo
def index(conn, _params) do
  users = Repo.all(User)  # 应该在 context 中！
  render(conn, "index.html", users: users)
end
```

### Controllers
✅ **好的做法：**
```elixir
def create(conn, %{"user" => user_params}) do
  case Accounts.create_user(user_params) do
    {:ok, user} ->
      conn
      |> put_flash(:info, "User created successfully")
      |> redirect(to: ~p"/users/#{user}")

    {:error, %Ecto.Changeset{} = changeset} ->
      render(conn, "new.html", changeset: changeset)
  end
end
```

❌ **不好的做法：**
```elixir
def create(conn, %{"user" => user_params}) do
  user = Accounts.create_user!(user_params)  # 未处理的异常！
  redirect(conn, to: ~p"/users/#{user}")
end
```

## 要避免的常见陷阱

- ❌ 在 controllers 中放置业务逻辑
- ❌ 从 controllers 直接访问 Repo
- ❌ 创建上帝 contexts（分成更小的 contexts）
- ❌ 不测试边界情况
- ❌ 忽视 N+1 查询警告
- ❌ 不使用数据库约束
- ❌ 以纯文本存储敏感数据
- ❌ 不实现授权检查
- ❌ 使用 `belongs_to` 而不使用 `foreign_key_constraint`
- ❌ 不对大结果集进行分页

## 标记故事完成前

- [ ] 上述所有检查项已审查
- [ ] `mix test` - 所有测试通过
- [ ] `mix credo --strict` - 无问题
- [ ] `mix dialyzer` - 无警告
- [ ] `mix format` - 代码已格式化
- [ ] 无编译器警告
- [ ] 文档完整
- [ ] 安全审查已完成
- [ ] 性能可接受
