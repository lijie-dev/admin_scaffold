# LiveView 最佳实践检查清单

在实现 Phoenix LiveView 功能时使用此检查清单，以确保遵循最佳实践并避免常见陷阱。

## 生命周期实现

### Mount
- [ ] 处理已连接和未连接状态
- [ ] 仅在 `connected?(socket)` 时订阅 PubSub
- [ ] 高效加载初始数据
- [ ] 设置所有必需的 assigns
- [ ] 对集合使用 streams（不使用常规 assigns）
- [ ] 返回 `{:ok, socket}` 或 `{:ok, socket, options}`

### Handle Event
- [ ] 所有交互元素都有 phx-* 属性
- [ ] 事件名称具有描述性（"save"、"delete"，而不是 "click"）
- [ ] 使用 `phx-value-*` 传递事件数据
- [ ] 更新后返回 `{:noreply, socket}`
- [ ] 提供用户反馈（flash、UI 更新）
- [ ] 优雅地处理错误

### Handle Info
- [ ] 正确处理 PubSub 消息
- [ ] 正确处理进程消息
- [ ] 根据消息更新 UI
- [ ] 返回 `{:noreply, socket}`

## Socket Assigns

### 最小化 Assigns
- [ ] 仅存储渲染所需的内容
- [ ] 对所有集合使用 streams
- [ ] 避免存储大型数据结构
- [ ] 不再需要时移除 assigns
- [ ] 对一次性数据使用临时 assigns

### 命名
- [ ] Assign 名称具有描述性
- [ ] 布尔 assigns 以 `?` 结尾（例如 `loading?`、`empty?`）
- [ ] 在 LiveViews 中保持一致的命名
- [ ] 避免使用 `data` 或 `info` 等通用名称

## Streams

### 使用
- [ ] 所有集合都使用 streams（不使用 assigns）
- [ ] 容器具有 `phx-update="stream"` 和唯一的 `id`
- [ ] Stream 项具有唯一的 `id` 属性：`<div id={id}>`
- [ ] 使用 `stream/3` 添加项
- [ ] 使用 `stream_delete/3` 移除项
- [ ] 使用 `stream_insert/4` 和 `at:` 进行定位
- [ ] 使用 `stream/4` 和 `reset: true` 重置

### 空状态
- [ ] 优雅地处理空集合
- [ ] 对空状态消息使用 Tailwind 的 `only:` 变体
- [ ] 当不存在项时提供清晰的消息

```elixir
<div id="products" phx-update="stream">
  <div class="hidden only:block">No products yet.</div>
  <div :for={{id, product} <- @streams.products} id={id}>
    ...
  </div>
</div>
```

## 表单

### 设置
- [ ] 使用 `to_form/1` 创建表单结构
- [ ] 表单具有唯一的 `id` 属性
- [ ] 实现 `phx-change="validate"` 进行实时验证
- [ ] 实现 `phx-submit="save"` 进行提交
- [ ] 使用来自 core_components 的 `<.input>` 组件

### 验证
- [ ] 使用 `action: :validate` 在更改时验证
- [ ] 内联显示错误
- [ ] 处理期间禁用提交按钮
- [ ] 成功提交后清除表单
- [ ] 提供清晰的成功/错误反馈

### 示例
```elixir
<.form
  for={@form}
  id="product-form"
  phx-change="validate"
  phx-submit="save"
>
  <.input field={@form[:name]} label="Name" />
  <.input field={@form[:price]} label="Price" type="number" />
  <.button phx-disable-with="Saving...">Save</.button>
</.form>
```

## 事件和交互

### 事件属性
- [ ] 对点击使用 `phx-click`
- [ ] 对表单提交使用 `phx-submit`
- [ ] 对表单/输入更改使用 `phx-change`
- [ ] 使用 `phx-value-*` 传递数据
- [ ] 对组件事件使用 `phx-target`
- [ ] 对搜索输入使用 `phx-debounce`

### 用户反馈
- [ ] 显示加载状态（`phx-disable-with`）
- [ ] 提供成功消息（flash 或内联）
- [ ] 清晰地显示错误消息
- [ ] 在适当的地方实现乐观 UI 更新
- [ ] 处理期间禁用按钮

## PubSub 和实时

### 订阅
- [ ] 仅在 `connected?(socket)` 时订阅
- [ ] 主题名称具有描述性且有作用域
- [ ] 断开连接时自动取消订阅（无需手动清理）
- [ ] 正确管理多个订阅

### 广播
- [ ] 成功变更后进行广播
- [ ] 包含 UI 更新所需的所有数据
- [ ] 广播到正确的主题
- [ ] 优雅地处理广播失败

### 示例
```elixir
def mount(_params, _session, socket) do
  if connected?(socket) do
    Phoenix.PubSub.subscribe(MyApp.PubSub, "products")
  end

  {:ok, stream(socket, :products, list_products())}
end

def handle_info({:product_created, product}, socket) do
  {:noreply, stream_insert(socket, :products, product, at: 0)}
end
```

## 性能

### 优化
- [ ] 对集合使用 streams 而不是 assigns
- [ ] 为大型数据集实现分页
- [ ] 在搜索/过滤输入上使用 `phx-debounce`
- [ ] 最小化 socket assigns
- [ ] 避免在模板中进行昂贵的计算
- [ ] 对外部 JS 使用 `phx-update="ignore"`

### 渲染
- [ ] 模板中没有重型计算
- [ ] 使用 `:if` 属性进行条件渲染
- [ ] 循环使用 `:for` 属性（不使用 Enum.map）
- [ ] 组件提取可重用的标记
- [ ] 尽可能预计算 CSS 类

## 测试

### Mount 测试
- [ ] 测试初始渲染
- [ ] 测试数据加载
- [ ] 测试空状态
- [ ] 测试错误状态
- [ ] 使用不同的用户权限进行测试

### 事件测试
- [ ] 测试所有 phx-click 处理程序
- [ ] 测试表单提交
- [ ] 测试表单验证
- [ ] 测试删除/更新操作
- [ ] 测试边界情况

### 集成测试
- [ ] 测试完整的用户流程
- [ ] 测试实时更新
- [ ] 测试并发用户（如适用）
- [ ] 测试 LiveViews 之间的导航

## 安全性

### 授权
- [ ] 在 mount 中检查用户权限
- [ ] 在每个事件上验证访问权限
- [ ] 不在 assigns 中暴露未授权的数据
- [ ] 无法访问其他用户的数据
- [ ] 适当的租户隔离（如果是多租户）

### 输入验证
- [ ] 验证所有事件参数
- [ ] 在 changeset 中验证表单数据
- [ ] 没有原始 HTML 注入
- [ ] CSRF 保护已启用（Phoenix 中的默认设置）

## 组件组织

### LiveComponents
- [ ] 仅在需要状态隔离时使用
- [ ] 具有唯一的 `id` 属性
- [ ] 通过 `send_update/2` 更新
- [ ] 与父组件的耦合最小

### 函数组件
- [ ] 对无状态 UI 优先于 LiveComponents
- [ ] 使用 `attr/3` 验证属性
- [ ] 对灵活的内容使用 slots
- [ ] 在 LiveViews 中可重用

## 常见模式

### 过滤
```elixir
def handle_event("filter", %{"filter" => filter}, socket) do
  products = list_products(filter)

  {:noreply,
   socket
   |> assign(:filter, filter)
   |> stream(:products, products, reset: true)}
end
```

### 分页
```elixir
def handle_event("load-more", _, socket) do
  page = socket.assigns.page + 1
  products = list_products(page: page)

  {:noreply,
   socket
   |> assign(:page, page)
   |> stream(:products, products)}
end
```

### 乐观 UI
```elixir
def handle_event("delete", %{"id" => id}, socket) do
  product = get_product!(id)

  # Optimistic update
  socket = stream_delete(socket, :products, product)

  # Async deletion
  Task.start(fn -> delete_product(product) end)

  {:noreply, socket}
end
```

## 常见陷阱

❌ **在 assigns 中存储集合**
```elixir
# Bad - stores entire list in socket
assign(socket, :products, list_products())

# Good - uses stream
stream(socket, :products, list_products())
```

❌ **在未连接时订阅**
```elixir
# Bad - subscribes even when not connected
def mount(_params, _session, socket) do
  Phoenix.PubSub.subscribe(MyApp.PubSub, "products")
  {:ok, socket}
end

# Good - only subscribe when connected
def mount(_params, _session, socket) do
  if connected?(socket) do
    Phoenix.PubSub.subscribe(MyApp.PubSub, "products")
  end
  {:ok, socket}
end
```

❌ **缺少 phx-update="stream"**
```elixir
# Bad - missing phx-update
<div id="products">  <!-- Missing phx-update="stream" -->
  <div :for={{id, p} <- @streams.products} id={id}>...</div>
</div>

# Good - has phx-update
<div id="products" phx-update="stream">
  <div :for={{id, p} <- @streams.products} id={id}>...</div>
</div>
```

❌ **不使用 to_form**
```elixir
# Bad - using changeset directly
<.form for={@changeset}>

# Good - using to_form
<.form for={@form}>  <!-- where @form = to_form(@changeset) -->
```

❌ **在模板中进行重型计算**
```elixir
# Bad - expensive calculation in template
<%= Enum.map(@products, &expensive_calculation/1) %>

# Good - precompute in handle_event/mount
products_with_data = Enum.map(products, &expensive_calculation/1)
assign(socket, :products_with_data, products_with_data)
```

## 完成前

- [ ] 所有事件已测试
- [ ] 实时更新正常工作
- [ ] 加载状态已实现
- [ ] 错误处理完成
- [ ] 性能可接受
- [ ] 没有内存泄漏（检查 socket assigns）
- [ ] 适用于多个并发用户
- [ ] 适当的授权检查
- [ ] 用户反馈清晰
- [ ] 边界情况已处理
