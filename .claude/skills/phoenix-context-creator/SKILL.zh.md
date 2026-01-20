---
name: phoenix-context-creator
description: 创建完整的 Phoenix contexts，遵循最佳实践，包括有界上下文、适当的 API 设计和全面的测试。在设计新功能或将代码重构为 contexts 时使用。
allowed-tools: Bash, Read, Edit, Write
---

# Phoenix Context Creator

本技能指导创建设计良好的 Phoenix contexts，遵循有界上下文原则和 Phoenix 最佳实践。

## 何时使用

- 创建新的业务域
- 组织相关功能
- 将代码重构为 contexts
- 设计 API 边界
- 构建功能模块

## 什么是 Context？

Context 是一个模块，它将相关功能分组在一起，并为该域提供公共 API。Contexts 在应用程序的不同部分之间强制执行边界。

**示例：**
- `Accounts` - 用户管理、身份验证
- `Catalog` - 产品、分类、库存
- `Sales` - 订单、购物车、结账
- `CMS` - 博客文章、页面、评论
- `Notifications` - 电子邮件、短信、推送通知

## Context 设计原则

### 1. 有界上下文

每个 context 应该有明确的职责：

```elixir
# 好的做法：专注的 contexts
Accounts.create_user()
Catalog.list_products()
Sales.place_order()

# 不好的做法：混合职责
Users.create_user()
Users.list_products()  # 产品不属于这里
Users.send_email()     # 电子邮件发送不属于这里
```

### 2. 仅公共 API

Contexts 暴露有意的 API，隐藏实现细节：

```elixir
# 好的做法：清晰、意图明确的 API
defmodule MyApp.Accounts do
  def list_users, do: Repo.all(User)
  def get_user!(id), do: Repo.get!(User, id)
  def create_user(attrs), do: %User{} |> User.changeset(attrs) |> Repo.insert()
end

# 不好的做法：暴露内部细节
defmodule MyApp.Accounts do
  # 不要直接暴露 User schema
  def user_schema, do: User

  # 不要暴露 changesets
  def user_changeset(attrs), do: User.changeset(%User{}, attrs)
end
```

### 3. 无跨 Context 依赖

Contexts 不应该直接引用其他 contexts 的 schemas：

```elixir
# 不好的做法：Post 直接引用 User schema
defmodule Blog.Post do
  schema "posts" do
    belongs_to :user, Accounts.User  # 直接 schema 引用
  end
end

# 好的做法：使用 ID 跨 contexts 引用
defmodule Blog.Post do
  schema "posts" do
    field :user_id, :id  # 仅存储 ID
  end
end

# 然后在 Blog context 中，委托用户查询给 Accounts
defmodule Blog do
  def get_post_with_author!(id) do
    post = get_post!(id)
    author = Accounts.get_user!(post.user_id)
    %{post | author: author}
  end
end
```

## 创建新 Context

### 步骤 1：规划域

**需要回答的问题：**
1. 主要职责是什么？
2. 主要实体是什么？
3. 需要哪些操作？
4. 它如何与其他 contexts 交互？

**示例：构建博客**
- 主要职责：内容管理
- 实体：Post、Comment、Tag
- 操作：CRUD posts、发布/取消发布、添加评论
- 交互：需要来自 Accounts context 的用户数据

### 步骤 2：生成 Context

```bash
# 使用主 schema 生成 context
mix phx.gen.context Blog Post posts \
  title:string \
  body:text \
  published:boolean \
  user_id:references:users \
  slug:string:unique
```

生成：
- Context: `lib/my_app/blog.ex`
- Schema: `lib/my_app/blog/post.ex`
- Migration: `priv/repo/migrations/*_create_posts.exs`
- Tests: `test/my_app/blog_test.exs`

### 步骤 3：设计公共 API

**从 CRUD 开始：**
```elixir
defmodule MyApp.Blog do
  alias MyApp.Blog.Post

  # 列表操作
  def list_posts
  def list_published_posts

  # 获取操作
  def get_post!(id)
  def get_post_by_slug(slug)

  # 创建/更新/删除
  def create_post(attrs)
  def update_post(post, attrs)
  def delete_post(post)

  # 特定域的操作
  def publish_post(post)
  def unpublish_post(post)
  def increment_view_count(post)
end
```

**添加业务逻辑：**
```elixir
def publish_post(%Post{} = post) do
  post
  |> Post.publish_changeset()
  |> Repo.update()
end

def list_posts_by_user(user_id) do
  Post
  |> where(user_id: ^user_id)
  |> order_by([desc: :inserted_at])
  |> Repo.all()
end
```

### 步骤 4：增强 Schema

```elixir
defmodule MyApp.Blog.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :title, :string
    field :body, :text
    field :published, :boolean, default: false
    field :slug, :string
    field :view_count, :integer, default: 0
    field :user_id, :id

    timestamps()
  end

  # 创建 changeset
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :body, :user_id])
    |> validate_required([:title, :body, :user_id])
    |> validate_length(:title, min: 3, max: 100)
    |> generate_slug()
    |> unique_constraint(:slug)
  end

  # 发布 changeset
  def publish_changeset(post) do
    change(post, published: true, published_at: DateTime.utc_now())
  end

  defp generate_slug(changeset) do
    case get_change(changeset, :title) do
      nil -> changeset
      title -> put_change(changeset, :slug, Slug.slugify(title))
    end
  end
end
```

### 步骤 5：添加额外的 Schemas

```bash
# 向博客 context 添加评论
mix phx.gen.context Blog Comment comments \
  body:text \
  post_id:references:posts \
  user_id:references:users \
  --merge-with-existing-context
```

### 步骤 6：编写全面的测试

```elixir
defmodule MyApp.BlogTest do
  use MyApp.DataCase

  alias MyApp.Blog

  describe "posts" do
    test "list_posts/0 returns all posts" do
      post = fixture(:post)
      assert Blog.list_posts() == [post]
    end

    test "get_post!/1 returns the post with given id" do
      post = fixture(:post)
      assert Blog.get_post!(post.id) == post
    end

    test "create_post/1 with valid data creates a post" do
      attrs = %{title: "Title", body: "Body", user_id: 1}
      assert {:ok, %Post{} = post} = Blog.create_post(attrs)
      assert post.title == "Title"
    end

    test "publish_post/1 marks post as published" do
      post = fixture(:post)
      assert {:ok, %Post{} = published} = Blog.publish_post(post)
      assert published.published == true
    end
  end
end
```

## Context 交互模式

### 模式 1：ID 引用（推荐）
```elixir
# Blog context 仅通过 ID 引用用户
defmodule MyApp.Blog do
  def create_post(user_id, attrs) do
    attrs
    |> Map.put(:user_id, user_id)
    |> create_post()
  end

  # 当需要用户数据时，委托给 Accounts
  def get_post_with_author(post_id) do
    post = get_post!(post_id)
    author = MyApp.Accounts.get_user!(post.user_id)
    Map.put(post, :author, author)
  end
end
```

### 模式 2：数据传输对象
```elixir
# Blog context 接受来自 Accounts 的 struct
defmodule MyApp.Blog do
  def create_post_for_user(%Accounts.User{id: user_id}, attrs) do
    create_post(Map.put(attrs, :user_id, user_id))
  end
end
```

### 模式 3：基于事件的通信
```elixir
# 当重要事件发生时发布事件
defmodule MyApp.Blog do
  def publish_post(post) do
    with {:ok, post} <- do_publish(post) do
      Phoenix.PubSub.broadcast(
        MyApp.PubSub,
        "posts",
        {:post_published, post}
      )
      {:ok, post}
    end
  end
end

# 其他 contexts 订阅事件
defmodule MyApp.Notifications do
  def handle_info({:post_published, post}, state) do
    send_notifications(post)
    {:noreply, state}
  end
end
```

## 常见 Context 模式

### Accounts Context
```elixir
defmodule MyApp.Accounts do
  # 用户管理
  def list_users
  def get_user!(id)
  def create_user(attrs)
  def update_user(user, attrs)
  def delete_user(user)

  # 身份验证
  def authenticate(email, password)
  def change_password(user, password)

  # 授权
  def assign_role(user, role)
  def has_permission?(user, permission)
end
```

### Catalog Context（电子商务）
```elixir
defmodule MyApp.Catalog do
  # 产品
  def list_products
  def get_product!(id)
  def create_product(attrs)

  # 分类
  def list_categories
  def get_category_products(category_id)

  # 搜索
  def search_products(query)
  def filter_products(filters)

  # 库存
  def check_availability(product_id, quantity)
  def reserve_stock(product_id, quantity)
end
```

### Sales Context（电子商务）
```elixir
defmodule MyApp.Sales do
  # 购物车
  def get_cart(user_id)
  def add_to_cart(user_id, product_id, quantity)
  def update_cart_item(cart_item, quantity)

  # 订单
  def create_order(user_id, cart_id)
  def get_order!(id)
  def cancel_order(order)

  # 结账
  def calculate_total(cart)
  def apply_discount(cart, code)
  def process_payment(order, payment_details)
end
```

## 要避免的反模式

### 1. 上帝 Context
```elixir
# 不好的做法：大杂烩 context
defmodule MyApp.Core do
  def create_user(attrs)
  def create_product(attrs)
  def send_email(attrs)
  def process_payment(attrs)
end

# 好的做法：专注的 contexts
MyApp.Accounts.create_user(attrs)
MyApp.Catalog.create_product(attrs)
MyApp.Notifications.send_email(attrs)
MyApp.Billing.process_payment(attrs)
```

### 2. 直接 Schema 访问
```elixir
# 不好的做法：Controllers 直接访问 schemas
def index(conn, _params) do
  users = Repo.all(User)  # 不要这样做！
  render(conn, "index.html", users: users)
end

# 好的做法：使用 context API
def index(conn, _params) do
  users = Accounts.list_users()
  render(conn, "index.html", users: users)
end
```

### 3. Context 耦合
```elixir
# 不好的做法：Blog 直接导入 Accounts
defmodule MyApp.Blog do
  alias MyApp.Accounts.User

  def create_post_with_user(attrs) do
    user = Repo.get!(User, attrs.user_id)  # 直接耦合
    # ...
  end
end

# 好的做法：使用 ID 并委托
defmodule MyApp.Blog do
  def create_post(attrs) do
    # 仅通过 ID 验证用户是否存在
    unless Accounts.user_exists?(attrs.user_id) do
      {:error, :user_not_found}
    else
      # 创建 post
    end
  end
end
```

## Context 组织

```
lib/my_app/
├── accounts/
│   ├── user.ex
│   ├── session.ex
│   └── role.ex
├── accounts.ex          # 公共 API
├── blog/
│   ├── post.ex
│   ├── comment.ex
│   └── tag.ex
├── blog.ex              # 公共 API
└── catalog/
    ├── product.ex
    ├── category.ex
    └── variant.ex
```

## 测试 Contexts

```elixir
defmodule MyApp.BlogTest do
  use MyApp.DataCase

  alias MyApp.Blog

  # 测试 context API，而不是内部函数
  describe "list_posts/0" do
    test "returns all posts" do
      # 设置
      post1 = fixture(:post)
      post2 = fixture(:post)

      # 执行
      posts = Blog.list_posts()

      # 断言
      assert length(posts) == 2
      assert post1 in posts
      assert post2 in posts
    end
  end

  describe "create_post/1" do
    test "with valid data" do
      attrs = %{title: "Title", body: "Body", user_id: 1}
      assert {:ok, post} = Blog.create_post(attrs)
      assert post.title == "Title"
    end

    test "with invalid data" do
      assert {:error, changeset} = Blog.create_post(%{})
      assert %{title: ["can't be blank"]} = errors_on(changeset)
    end
  end
end
```

## 迁移策略

### 添加到现有代码库

1. **识别边界** - 分组相关功能
2. **创建 Context** - 从一个清晰的边界开始
3. **移动 Schemas** - 重新定位相关 schemas
4. **提取函数** - 将函数拉入 context
5. **更新引用** - 更新 controllers/views
6. **编写测试** - 确保没有破坏任何东西
7. **重复** - 继续处理其他边界

### 重构示例

**之前：**
```elixir
# 所有内容都在一个地方
defmodule MyAppWeb.UserController do
  def index(conn, _params) do
    users = Repo.all(User)
    render(conn, "index.html", users: users)
  end
end
```

**之后：**
```elixir
# Context 层
defmodule MyApp.Accounts do
  def list_users, do: Repo.all(User)
end

# Controller 使用 context
defmodule MyAppWeb.UserController do
  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, "index.html", users: users)
  end
end
```
