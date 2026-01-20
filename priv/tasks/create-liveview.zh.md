# 任务：创建 LiveView 功能

**目的**：使用 Phoenix LiveView 实现交互式、实时功能

**代理**：elixir-dev

**预计时长**：2-6 小时（取决于复杂度）

## 概述

LiveView 使您能够创建丰富的实时用户体验，无需编写 JavaScript。遵循 AGENTS.md 中的既定模式和 LiveView 检查清单。

## 前置条件

- Context 和 schemas 已存在
- 理解 LiveView 生命周期（mount、handle_event、handle_info）
- 熟悉 streams（而非 assigns）用于集合

## 第 1 步：规划 LiveView 结构

**预计时长**：30 分钟

回答以下问题：

**状态管理：**
- 哪些数据需要在 socket assigns 中？
- 哪些应该计算而不是存储？
- 我们是否为集合使用 streams？（答案：对所有集合使用 YES）

**用户交互：**
- 哪些按钮/表单将触发事件？
- 需要哪些 phx-* 属性？
- 表单是否使用实时验证？

**实时更新：**
- 这是否需要 PubSub 进行跨用户更新？
- 哪些事件应该触发广播？
- 乐观 UI 应该如何工作？

**示例规划：**
```
功能：产品搜索和管理
Socket Assigns：
  - @search_query (字符串)
  - @selected_category (id 或 nil)
  - @form (用于新建/编辑产品)
Streams：
  - @streams.products (使用 streams，不是 assigns！)
事件：
  - "search" - 过滤产品
  - "select_category" - 按类别过滤
  - "delete" - 删除产品
  - "save" - 创建/更新产品
PubSub：
  - 订阅 "products" 主题
  - 在创建/更新/删除时广播
```

## 第 2 步：生成 LiveView（可选）

**预计时长**：5-10 分钟

```bash
# 完整 CRUD 脚手架
mix phx.gen.live Catalog Product products name:string price:decimal sku:string

# 或手动创建以获得更多控制
```

生成器创建：
- `lib/my_app_web/live/product_live/index.ex`
- `lib/my_app_web/live/product_live/show.ex`
- `lib/my_app_web/live/product_live/form_component.ex`
- router.ex 中的路由

## 第 3 步：实现 Mount

**预计时长**：30 分钟 - 1 小时

### AGENTS.md 中的关键规则：
- 仅当 `connected?(socket)` 时订阅 PubSub
- 对集合使用 **streams**，永远不要对列表使用 assigns
- 处理连接和未连接状态

```elixir
defmodule MyAppWeb.ProductLive.Index do
  use MyAppWeb, :live_view

  alias MyApp.Catalog
  alias MyApp.Catalog.Product

  @impl true
  def mount(_params, _session, socket) do
    # PubSub 订阅 - 仅当连接时
    if connected?(socket) do
      Phoenix.PubSub.subscribe(MyApp.PubSub, "products")
    end

    {:ok,
     socket
     |> assign(:page_title, "Listing Products")
     |> assign(:search_query, "")
     |> assign(:selected_category, nil)
     |> stream(:products, Catalog.list_products())}
  end

  # 带表单的替代方案
  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(MyApp.PubSub, "products")
    end

    {:ok,
     socket
     |> assign(:page_title, "Listing Products")
     |> assign(:search_query, "")
     |> stream(:products, Catalog.list_products())
     |> assign(:form, to_form(Catalog.change_product(%Product{})))}
  end
end
```

## 第 4 步：实现事件处理器

**预计时长**：1-2 小时

### 搜索/过滤事件

```elixir
@impl true
def handle_event("search", %{"search" => query}, socket) do
  products = Catalog.search_products(query)

  {:noreply,
   socket
   |> assign(:search_query, query)
   |> stream(:products, products, reset: true)}  # 使用新结果重置 stream
end

@impl true
def handle_event("filter_category", %{"category_id" => category_id}, socket) do
  products = Catalog.list_products(filters: %{category_id: category_id})

  {:noreply,
   socket
   |> assign(:selected_category, category_id)
   |> stream(:products, products, reset: true)}
end

@impl true
def handle_event("clear_filters", _params, socket) do
  products = Catalog.list_products()

  {:noreply,
   socket
   |> assign(:search_query, "")
   |> assign(:selected_category, nil)
   |> stream(:products, products, reset: true)}
end
```

### 表单事件（遵循 AGENTS.md 规则）

**关键：始终使用 `to_form/1`，永远不要将 changeset 传递给模板！**

```elixir
@impl true
def handle_event("validate", %{"product" => product_params}, socket) do
  changeset =
    socket.assigns.product
    |> Catalog.change_product(product_params)
    |> Map.put(:action, :validate)

  # 使用 to_form/1 - 永远不要将 changeset 传递给模板
  {:noreply, assign(socket, :form, to_form(changeset))}
end

@impl true
def handle_event("save", %{"product" => product_params}, socket) do
  case Catalog.create_product(product_params) do
    {:ok, product} ->
      {:noreply,
       socket
       |> put_flash(:info, "Product created successfully")
       |> stream_insert(:products, product, at: 0)}  # 预置到 stream

    {:error, %Ecto.Changeset{} = changeset} ->
      # 将 changeset 转换为表单
      {:noreply, assign(socket, :form, to_form(changeset))}
  end
end
```

### 删除事件

```elixir
@impl true
def handle_event("delete", %{"id" => id}, socket) do
  product = Catalog.get_product!(id)

  case Catalog.delete_product(product) do
    {:ok, _product} ->
      {:noreply,
       socket
       |> put_flash(:info, "Product deleted successfully")
       |> stream_delete(:products, product)}

    {:error, _changeset} ->
      {:noreply,
       socket
       |> put_flash(:error, "Could not delete product")}
  end
end
```

## 第 5 步：实现 PubSub 处理器

**预计时长**：30 分钟 - 1 小时

处理来自其他进程/用户的广播：

```elixir
@impl true
def handle_info({:product_created, product}, socket) do
  # 另一个用户创建了产品 - 预置到 stream
  {:noreply, stream_insert(socket, :products, product, at: 0)}
end

@impl true
def handle_info({:product_updated, product}, socket) do
  # 另一个用户更新了产品 - 在 stream 中更新
  {:noreply, stream_insert(socket, :products, product)}
end

@impl true
def handle_info({:product_deleted, product}, socket) do
  # 另一个用户删除了产品 - 从 stream 中移除
  {:noreply, stream_delete(socket, :products, product)}
end
```

## 第 6 步：构建模板

**预计时长**：1-2 小时

### AGENTS.md 中的关键规则：
- 对属性插值使用 `{...}`
- 对正文中的块构造使用 `<%= ... %>`
- 使用 `:for` 属性，不要使用 `Enum.map`
- 没有 `else if` - 改用 `cond`
- Streams 需要 `phx-update="stream"` 和唯一 ID

```heex
<.header>
  Listing Products
  <:actions>
    <.link patch={~p"/products/new"}>
      <.button>New Product</.button>
    </.link>
  </:actions>
</.header>

<%!-- 带防抖的搜索表单 --%>
<.simple_form for={%{}} id="search-form" phx-change="search">
  <.input
    name="search"
    value={@search_query}
    placeholder="Search products..."
    phx-debounce="300"
  />
</.simple_form>

<%!-- 产品 Stream（关键：需要 phx-update="stream"！） --%>
<div id="products" phx-update="stream">
  <%!-- 空状态（使用 Tailwind 的 only: 变体） --%>
  <div class="hidden only:block text-gray-500 text-center py-8">
    No products yet. Click "New Product" to add one.
  </div>

  <%!-- 产品项目 --%>
  <div
    :for={{id, product} <- @streams.products}
    id={id}
    class="border rounded-lg p-4 mb-2"
  >
    <div class="flex justify-between items-start">
      <div>
        <h3 class="font-bold">{product.name}</h3>
        <p class="text-gray-600">{product.description}</p>
        <p class="text-lg font-semibold">${product.price}</p>
      </div>
      <div class="flex gap-2">
        <.link patch={~p"/products/#{product}/edit"}>
          <.button>Edit</.button>
        </.link>
        <.button
          phx-click="delete"
          phx-value-id={product.id}
          data-confirm="Are you sure?"
        >
          Delete
        </.button>
      </div>
    </div>
  </div>
</div>

<%!-- 新建/编辑产品的模态框 --%>
<.modal
  :if={@live_action in [:new, :edit]}
  id="product-modal"
  show
  on_cancel={JS.patch(~p"/products")}
>
  <.live_component
    module={MyAppWeb.ProductLive.FormComponent}
    id={@product.id || :new}
    title={@page_title}
    action={@live_action}
    product={@product}
    patch={~p"/products"}
  />
</.modal>
```

### 表单组件模板

**关键：使用 `<.form for={@form}>`，不要使用 `<.form for={@changeset}>`！**

```heex
<div>
  <.header>
    {@title}
  </.header>

  <%!-- 使用 @form，永远不要在模板中使用 @changeset --%>
  <.simple_form
    for={@form}
    id="product-form"
    phx-target={@myself}
    phx-change="validate"
    phx-submit="save"
  >
    <%!-- 使用 @form[:field]，永远不要使用 @changeset[:field] --%>
    <.input field={@form[:name]} type="text" label="Name" />
    <.input field={@form[:description]} type="textarea" label="Description" />
    <.input field={@form[:price]} type="number" label="Price" step="0.01" />
    <.input field={@form[:sku]} type="text" label="SKU" />
    <.input field={@form[:quantity]} type="number" label="Quantity" />
    <.input field={@form[:active]} type="checkbox" label="Active" />

    <:actions>
      <.button phx-disable-with="Saving...">Save Product</.button>
    </:actions>
  </.simple_form>
</div>
```

## 第 7 步：添加 LiveView 测试

**预计时长**：1-2 小时

参见 `write-tests.md` 获取全面的测试指南。

**AGENTS.md 中的关键规则：**
- 始终在模板中使用元素 ID 进行测试
- 使用 `has_element?/2`、`element/2` - 永远不要测试原始 HTML
- 针对实际 HTML 输出结构进行测试
- 使用 `LazyHTML` 调试复杂选择器

```elixir
defmodule MyAppWeb.ProductLiveTest do
  use MyAppWeb.ConnCase

  import Phoenix.LiveViewTest
  import MyApp.CatalogFixtures

  describe "Index" do
    test "lists all products", %{conn: conn} do
      product = product_fixture()
      {:ok, _index_live, html} = live(conn, ~p"/products")

      assert html =~ "Listing Products"
      assert html =~ product.name
    end

    test "saves new product", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/products")

      # 点击新建产品按钮
      assert index_live |> element("a", "New Product") |> render_click() =~
               "New Product"

      # 测试验证
      assert index_live
             |> form("#product-form", product: %{name: "", price: "invalid"})
             |> render_change() =~ "can&#39;t be blank"

      # 提交表单
      assert index_live
             |> form("#product-form",
               product: %{name: "Widget", price: "9.99", sku: "WID-001"}
             )
             |> render_submit()

      # 验证产品出现（测试 stream 更新）
      assert_patch(index_live, ~p"/products")
      html = render(index_live)
      assert html =~ "Widget"
    end

    test "deletes product in listing", %{conn: conn} do
      product = product_fixture()
      {:ok, index_live, _html} = live(conn, ~p"/products")

      # 验证产品存在
      assert has_element?(index_live, "#products-#{product.id}")

      # 删除产品
      assert index_live
             |> element("#products-#{product.id} button", "Delete")
             |> render_click()

      # 验证产品从 stream 中移除
      refute has_element?(index_live, "#products-#{product.id}")
    end

    test "searches products", %{conn: conn} do
      widget = product_fixture(name: "Widget")
      _gadget = product_fixture(name: "Gadget")

      {:ok, index_live, _html} = live(conn, ~p"/products")

      # 搜索（带防抖）
      index_live
      |> element("#search-form")
      |> render_change(%{search: "widget"})

      html = render(index_live)
      assert html =~ "Widget"
      refute html =~ "Gadget"
    end
  end
end
```

## 第 8 步：优化性能

**预计时长**：30 分钟

### 使用 Streams（不是 Assigns）

```elixir
# 不好：在 assigns 中存储列表（内存膨胀！）
assign(socket, :products, list_products())

# 好：使用 streams（高效！）
stream(socket, :products, list_products())
```

### 实现防抖

```heex
<%!-- 防抖搜索输入 --%>
<.input
  name="search"
  phx-debounce="300"
  placeholder="Search..."
/>
```

### 最小化 Socket Assigns

```elixir
# 不好：存储计算数据
socket
|> assign(:products, products)
|> assign(:product_count, length(products))  # 冗余！
|> assign(:total_price, calculate_total(products))  # 昂贵！

# 好：仅存储需要的内容，在模板或 LiveView 中计算
socket
|> stream(:products, products)
```

### 临时 Assigns

```elixir
# 对于一次性数据，使用临时 assigns
socket
|> assign(:flash_message, "Success!")
|> assign(:temp_data, large_data)  # 渲染后将被清除
```

## 常见陷阱（来自 AGENTS.md）

### 不使用 Streams

```elixir
# 错误 - 大列表导致内存膨胀
def mount(_params, _session, socket) do
  {:ok, assign(socket, :products, list_products())}
end

# 正确 - 使用 streams
def mount(_params, _session, socket) do
  {:ok, stream(socket, :products, list_products())}
end
```

### 缺少 phx-update="stream"

```heex
<%!-- 错误 - 没有 phx-update 的 stream 不会工作 --%>
<div id="products">
  <div :for={{id, p} <- @streams.products} id={id}>...</div>
</div>

<%!-- 正确 - 有 phx-update="stream" --%>
<div id="products" phx-update="stream">
  <div :for={{id, p} <- @streams.products} id={id}>...</div>
</div>
```

### 在模板中使用 Changeset

```heex
<%!-- 禁止 - 永远不要在模板中使用 @changeset！ --%>
<.form for={@changeset} id="my-form">
  <.input field={@changeset[:name]} />
</.form>

<%!-- 正确 - 始终使用来自 to_form/1 的 @form --%>
<.form for={@form} id="my-form">
  <.input field={@form[:name]} />
</.form>
```

### 未连接时订阅

```elixir
# 错误 - 即使在静态渲染时也订阅
def mount(_params, _session, socket) do
  Phoenix.PubSub.subscribe(MyApp.PubSub, "products")
  {:ok, socket}
end

# 正确 - 仅在连接时订阅
def mount(_params, _session, socket) do
  if connected?(socket) do
    Phoenix.PubSub.subscribe(MyApp.PubSub, "products")
  end
  {:ok, socket}
end
```

### 在 HEEx 中使用 `else if`

```heex
<%!-- 无效 - Elixir 没有 else if！ --%>
<%= if @status == :active do %>
  Active
<% else if @status == :pending %>
  Pending
<% end %>

<%!-- 正确 - 使用 cond --%>
<%= cond do %>
  <% @status == :active -> %>
    Active
  <% @status == :pending -> %>
    Pending
  <% true -> %>
    Unknown
<% end %>
```

## 检查清单

完成前检查：

- [ ] Mount 处理连接和未连接状态
- [ ] PubSub 仅在 `connected?(socket)` 时订阅
- [ ] 所有集合使用 streams（不是 assigns）
- [ ] Streams 在模板中有 `phx-update="stream"`
- [ ] Stream 项目有唯一的 `id={id}` 属性
- [ ] 表单使用 `to_form/1`（模板中永远不要使用原始 changeset）
- [ ] 表单使用来自 core_components 的 `<.input>` 组件
- [ ] 使用 phx-change="validate" 实现表单验证
- [ ] 处理空状态（使用 Tailwind 的 `only:` 变体）
- [ ] 事件处理器返回 `{:noreply, socket}`
- [ ] PubSub 处理器正确更新 UI
- [ ] LiveView 测试覆盖 mount、事件和表单
- [ ] 测试实时更新
- [ ] 模板中没有 `else if`（使用 `cond`）
- [ ] 搜索输入上有防抖
- [ ] 显示加载状态（phx-disable-with）
- [ ] 所有交互元素上有唯一的 DOM ID

## 后续步骤

完成 LiveView 后：
1. 运行 `mix test` - 验证所有测试通过
2. 在浏览器中运行 LiveView - 测试交互
3. 使用多个浏览器标签页测试实时更新
4. 检查日志中的 N+1 查询
5. 监控大数据集的内存使用情况
6. 记录任何 LiveView 特定的行为
