# 任务：编写全面的测试

**目的**：为 Elixir/Phoenix 代码创建全面、可维护的测试覆盖

**代理**：elixir-dev

**时长**：2-4 小时（取决于复杂性）

## 概述

全面的测试确保代码质量、防止回归，并记录预期行为。遵循 TDD 原则：先编写测试，看它们失败，实现代码，看它们通过。

## 测试类别

### 1. Context 测试（单元测试）

隔离测试业务逻辑。

**文件位置**：`test/my_app/context_name_test.exs`

**示例**：
```elixir
defmodule MyApp.AccountsTest do
  use MyApp.DataCase

  alias MyApp.Accounts

  describe "list_users/0" do
    test "returns all users" do
      user = user_fixture()
      assert Accounts.list_users() == [user]
    end

    test "returns empty list when no users" do
      assert Accounts.list_users() == []
    end

    test "preloads associations when requested" do
      user = user_fixture()
      [loaded_user] = Accounts.list_users(preload: [:posts])
      assert Ecto.assoc_loaded?(loaded_user.posts)
    end
  end

  describe "get_user/1" do
    test "returns user when exists" do
      user = user_fixture()
      assert {:ok, found_user} = Accounts.get_user(user.id)
      assert found_user.id == user.id
    end

    test "returns error when not found" do
      assert {:error, :not_found} = Accounts.get_user(999)
    end
  end

  describe "create_user/1" do
    test "creates user with valid attributes" do
      attrs = %{email: "test@example.com", name: "Test User"}
      assert {:ok, %User{} = user} = Accounts.create_user(attrs)
      assert user.email == "test@example.com"
      assert user.name == "Test User"
    end

    test "returns error with invalid attributes" do
      attrs = %{email: "invalid", name: ""}
      assert {:error, %Ecto.Changeset{} = changeset} = Accounts.create_user(attrs)
      assert "is invalid" in errors_on(changeset).email
      assert "can't be blank" in errors_on(changeset).name
    end

    test "enforces unique email constraint" do
      user_fixture(email: "test@example.com")
      attrs = %{email: "test@example.com", name: "Another User"}

      assert {:error, changeset} = Accounts.create_user(attrs)
      assert "has already been taken" in errors_on(changeset).email
    end

    test "enforces foreign key constraint" do
      attrs = %{email: "test@example.com", name: "Test", organization_id: 999}

      assert {:error, changeset} = Accounts.create_user(attrs)
      assert "does not exist" in errors_on(changeset).organization_id
    end
  end

  describe "update_user/2" do
    test "updates user with valid attributes" do
      user = user_fixture()
      attrs = %{name: "Updated Name"}

      assert {:ok, updated_user} = Accounts.update_user(user, attrs)
      assert updated_user.name == "Updated Name"
      assert updated_user.email == user.email  # 未改变
    end

    test "returns error with invalid attributes" do
      user = user_fixture()
      attrs = %{email: "invalid"}

      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, attrs)
    end
  end

  describe "delete_user/1" do
    test "deletes the user" do
      user = user_fixture()

      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert {:error, :not_found} = Accounts.get_user(user.id)
    end

    test "prevents deletion when user has associated records" do
      user = user_fixture()
      post_fixture(user: user)  # 创建关联的帖子

      assert {:error, changeset} = Accounts.delete_user(user)
      assert "has associated records" in errors_on(changeset).base
    end
  end
end
```

### 2. LiveView 测试（集成测试）

测试 UI 交互和实时更新。

**文件位置**：`test/my_app_web/live/resource_live_test.exs`

**来自 AGENTS.md 的关键原则**：
- 使用 `Phoenix.LiveViewTest` 和 `LazyHTML` 进行断言
- **始终**针对元素 ID 进行测试，而不是原始 HTML
- 使用 `element/2`、`has_element?/2`，永远不要测试原始 HTML 字符串
- 表单由 `render_submit/2` 和 `render_change/2` 驱动
- 在模板中为元素添加唯一的 DOM ID 以便测试

**示例**：
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

    test "displays empty state when no products", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/products")

      # 测试空状态元素（使用 Tailwind 的 only: 类）
      assert html =~ "No products yet"
    end

    test "saves new product", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/products")

      # 点击"新建产品"按钮
      assert index_live
             |> element("a", "New Product")
             |> render_click() =~ "New Product"

      # 测试表单验证
      assert index_live
             |> form("#product-form", product: %{name: "", price: "invalid"})
             |> render_change() =~ "can&#39;t be blank"

      # 提交表单
      assert index_live
             |> form("#product-form", product: %{name: "Widget", price: "9.99"})
             |> render_submit()

      # 验证重定向和新产品出现
      assert_patch(index_live, ~p"/products")

      html = render(index_live)
      assert html =~ "Product created successfully"
      assert html =~ "Widget"
    end

    test "updates product in listing", %{conn: conn} do
      product = product_fixture()
      {:ok, index_live, _html} = live(conn, ~p"/products")

      # 点击编辑按钮（使用 ID 定位）
      assert index_live
             |> element("#product-#{product.id} a", "Edit")
             |> render_click() =~ "Edit Product"

      # 更新产品
      assert index_live
             |> form("#product-form", product: %{name: "Updated Widget"})
             |> render_submit()

      assert_patch(index_live, ~p"/products")

      html = render(index_live)
      assert html =~ "Product updated successfully"
      assert html =~ "Updated Widget"
    end

    test "deletes product in listing", %{conn: conn} do
      product = product_fixture()
      {:ok, index_live, _html} = live(conn, ~p"/products")

      # 点击删除按钮
      assert index_live
             |> element("#product-#{product.id} button", "Delete")
             |> render_click()

      # 验证产品不再出现
      refute has_element?(index_live, "#product-#{product.id}")
    end

    test "filters products by search", %{conn: conn} do
      widget = product_fixture(name: "Widget")
      gadget = product_fixture(name: "Gadget")

      {:ok, index_live, _html} = live(conn, ~p"/products")

      # 搜索"widget"（带防抖）
      index_live
      |> element("#search-form")
      |> render_change(%{search: "widget"})

      html = render(index_live)
      assert html =~ "Widget"
      refute html =~ "Gadget"
    end
  end

  describe "Show" do
    test "displays product", %{conn: conn} do
      product = product_fixture()
      {:ok, _show_live, html} = live(conn, ~p"/products/#{product.id}")

      assert html =~ "Show Product"
      assert html =~ product.name
    end

    test "updates product within modal", %{conn: conn} do
      product = product_fixture()
      {:ok, show_live, _html} = live(conn, ~p"/products/#{product.id}")

      # 打开编辑模态框
      assert show_live
             |> element("a", "Edit")
             |> render_click() =~ "Edit Product"

      # 提交表单
      assert show_live
             |> form("#product-form", product: %{name: "Updated"})
             |> render_submit()

      assert_patch(show_live, ~p"/products/#{product.id}")

      html = render(show_live)
      assert html =~ "Product updated successfully"
      assert html =~ "Updated"
    end
  end

  describe "Real-time updates" do
    test "receives updates when another user creates product", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/products")

      # 模拟另一个用户创建产品（触发 PubSub 广播）
      product = product_fixture()

      # LiveView 应该接收并显示新产品
      assert render(index_live) =~ product.name
    end

    test "receives updates when another user deletes product", %{conn: conn} do
      product = product_fixture()
      {:ok, index_live, _html} = live(conn, ~p"/products")

      # 验证产品已显示
      assert has_element?(index_live, "#product-#{product.id}")

      # 模拟另一个用户删除（触发 PubSub 广播）
      Catalog.delete_product(product)

      # LiveView 应该移除产品
      refute has_element?(index_live, "#product-#{product.id}")
    end
  end
end
```

### 3. Controller 测试（API 测试）

测试 API 端点和 JSON 响应。

**文件位置**：`test/my_app_web/controllers/resource_controller_test.exs`

**示例**：
```elixir
defmodule MyAppWeb.API.ProductControllerTest do
  use MyAppWeb.ConnCase

  import MyApp.CatalogFixtures

  @create_attrs %{name: "Widget", price: "9.99"}
  @invalid_attrs %{name: nil, price: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all products", %{conn: conn} do
      product = product_fixture()

      conn = get(conn, ~p"/api/products")

      assert json_response(conn, 200)["data"] == [
        %{
          "id" => product.id,
          "name" => product.name,
          "price" => "9.99"
        }
      ]
    end
  end

  describe "create product" do
    test "renders product when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/products", product: @create_attrs)

      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/products/#{id}")

      assert %{
        "id" => ^id,
        "name" => "Widget",
        "price" => "9.99"
      } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/products", product: @invalid_attrs)

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update product" do
    test "renders product when data is valid", %{conn: conn} do
      product = product_fixture()

      conn = put(conn, ~p"/api/products/#{product.id}", product: %{name: "Updated"})

      assert %{"id" => id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/products/#{id}")

      assert %{"name" => "Updated"} = json_response(conn, 200)["data"]
    end
  end

  describe "delete product" do
    test "deletes chosen product", %{conn: conn} do
      product = product_fixture()

      conn = delete(conn, ~p"/api/products/#{product.id}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/products/#{product.id}")
      end
    end
  end
end
```

### 4. Schema/Changeset 测试

测试验证和转换。

**示例**：
```elixir
defmodule MyApp.Accounts.UserTest do
  use MyApp.DataCase

  alias MyApp.Accounts.User

  describe "changeset/2" do
    test "valid changeset with all required fields" do
      attrs = %{email: "test@example.com", name: "Test User"}
      changeset = User.changeset(%User{}, attrs)

      assert changeset.valid?
    end

    test "invalid without email" do
      attrs = %{name: "Test User"}
      changeset = User.changeset(%User{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).email
    end

    test "invalid with malformed email" do
      attrs = %{email: "invalid", name: "Test User"}
      changeset = User.changeset(%User, attrs)

      refute changeset.valid?
      assert "must have the @ sign" in errors_on(changeset).email
    end

    test "invalid with short name" do
      attrs = %{email: "test@example.com", name: "A"}
      changeset = User.changeset(%User{}, attrs)

      refute changeset.valid?
      assert "should be at least 2 character(s)" in errors_on(changeset).name
    end

    test "trims whitespace from name" do
      attrs = %{email: "test@example.com", name: "  Test User  "}
      changeset = User.changeset(%User{}, attrs)

      assert Ecto.Changeset.get_change(changeset, :name) == "Test User"
    end

    test "lowercases email" do
      attrs = %{email: "TEST@EXAMPLE.COM", name: "Test User"}
      changeset = User.changeset(%User{}, attrs)

      assert Ecto.Changeset.get_change(changeset, :email) == "test@example.com"
    end
  end
end
```

### 5. GenServer/Process 测试

测试并发进程和 OTP 行为。

**示例**：
```elixir
defmodule MyApp.Workers.NotificationWorkerTest do
  use MyApp.DataCase

  alias MyApp.Workers.NotificationWorker

  describe "start_link/1" do
    test "starts the worker" do
      assert {:ok, pid} = NotificationWorker.start_link(user_id: 123)
      assert Process.alive?(pid)
    end
  end

  describe "send_notification/2" do
    test "sends notification and updates state" do
      {:ok, pid} = NotificationWorker.start_link(user_id: 123)

      assert :ok = NotificationWorker.send_notification(pid, "Test message")

      # 使用 :sys.get_state 测试 GenServer 状态（仅测试）
      state = :sys.get_state(pid)
      assert state.sent_count == 1
    end

    test "handles concurrent notifications" do
      {:ok, pid} = NotificationWorker.start_link(user_id: 123)

      # 并发发送多个通知
      tasks = for i <- 1..10 do
        Task.async(fn ->
          NotificationWorker.send_notification(pid, "Message #{i}")
        end)
      end

      # 等待全部完成
      Enum.each(tasks, &Task.await/1)

      # 验证全部已处理
      state = :sys.get_state(pid)
      assert state.sent_count == 10
    end
  end

  describe "handle_info/2" do
    test "processes scheduled notifications" do
      {:ok, pid} = NotificationWorker.start_link(user_id: 123)

      # 直接向进程发送消息
      send(pid, :send_scheduled)

      # 等待处理
      :timer.sleep(100)

      state = :sys.get_state(pid)
      assert state.scheduled_sent == true
    end
  end
end
```

## 测试最佳实践

### 使用数据工厂

**永远不要重复测试数据创建**：

```elixir
# test/support/fixtures/catalog_fixtures.ex
defmodule MyApp.CatalogFixtures do
  def product_fixture(attrs \\ %{}) do
    {:ok, product} =
      attrs
      |> Enum.into(%{
        name: "Test Product",
        price: Decimal.new("9.99"),
        sku: "TEST-#{System.unique_integer()}"
      })
      |> MyApp.Catalog.create_product()

    product
  end

  def product_with_category_fixture(attrs \\ %{}) do
    category = category_fixture()
    product_fixture(Map.put(attrs, :category_id, category.id))
  end
end
```

### 测试边界情况

```elixir
describe "pagination" do
  test "returns first page" do
    # 创建 25 个产品
    for i <- 1..25, do: product_fixture(name: "Product #{i}")

    assert {:ok, page} = Catalog.list_products(page: 1, per_page: 10)
    assert length(page.entries) == 10
    assert page.page_number == 1
    assert page.total_pages == 3
  end

  test "returns last page with remaining items" do
    for i <- 1..25, do: product_fixture(name: "Product #{i}")

    assert {:ok, page} = Catalog.list_products(page: 3, per_page: 10)
    assert length(page.entries) == 5  # 最后一页只有 5 项
  end

  test "returns empty page when page number too high" do
    assert {:ok, page} = Catalog.list_products(page: 999, per_page: 10)
    assert page.entries == []
  end
end
```

### 测试并发访问

```elixir
test "handles concurrent updates correctly" do
  product = product_fixture(quantity: 10)

  # 模拟 5 个用户并发购买
  tasks = for _ <- 1..5 do
    Task.async(fn ->
      Catalog.purchase_product(product.id, quantity: 2)
    end)
  end

  results = Enum.map(tasks, &Task.await/1)

  # 全部应该成功（乐观锁定）
  assert Enum.all?(results, &match?({:ok, _}, &1))

  # 最终数量应该是 0
  assert Catalog.get_product!(product.id).quantity == 0
end
```

### 调试失败的测试

当测试因元素选择器失败时：

```elixir
test "complex selector debugging", %{conn: conn} do
  {:ok, view, _html} = live(conn, ~p"/products")

  # 获取 HTML
  html = render(view)

  # 使用 LazyHTML 解析
  document = LazyHTML.from_fragment(html)

  # 测试你的选择器
  matches = LazyHTML.filter(document, "#product-list .product-item")
  IO.inspect(matches, label: "Found Elements")

  # 现在编写正确的断言
  assert has_element?(view, "#product-list .product-item")
end
```

## 测试组织

### 分组相关测试

```elixir
describe "CRUD operations" do
  # 所有创建/读取/更新/删除测试
end

describe "validations" do
  # 所有验证测试
end

describe "edge cases" do
  # 边界条件、错误情况
end
```

### 使用 Setup 回调

```elixir
describe "authenticated user actions" do
  setup [:create_user, :log_in_user]

  test "can view dashboard", %{conn: conn} do
    conn = get(conn, ~p"/dashboard")
    assert html_response(conn, 200) =~ "Dashboard"
  end

  defp create_user(_context) do
    user = user_fixture()
    %{user: user}
  end

  defp log_in_user(%{conn: conn, user: user}) do
    %{conn: log_in_user(conn, user)}
  end
end
```

## 测试覆盖率

运行覆盖率：
```bash
mix test --cover
```

目标：新代码覆盖率 >= 80%

检查详细覆盖率：
```bash
mix test --cover
open cover/excoveralls.html
```

## 常见陷阱

### 测试实现细节

```elixir
# 不好：测试内部状态
test "increments counter" do
  {:ok, pid} = Worker.start_link()
  Worker.increment(pid)
  assert :sys.get_state(pid).counter == 1  # 过度耦合到实现
end

# 好：测试行为
test "emits event after increment" do
  {:ok, pid} = Worker.start_link()
  Worker.increment(pid)
  assert_receive {:counter_incremented, 1}
end
```

### 不使用异步

```elixir
# 不好：顺序测试（慢）
use MyApp.DataCase

# 好：并行测试（快）
use MyApp.DataCase, async: true
```

### 测试之间的共享状态

```elixir
# 不好：测试相互影响
@moduledoc "counter"
@counter 0  # 共享状态！

test "increments", do: @counter = @counter + 1  # 影响其他测试！

# 好：每个测试隔离
test "increments" do
  counter = 0
  new_counter = counter + 1
  assert new_counter == 1
end
```

## 后续步骤

编写测试后：
1. 运行 `mix test` - 确保全部通过
2. 运行 `mix test --cover` - 检查覆盖率
3. 查看测试输出中的警告
4. 与实现一起提交测试
