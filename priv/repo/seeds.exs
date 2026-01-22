# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     AdminScaffold.Repo.insert!(%AdminScaffold.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias AdminScaffold.Repo
alias AdminScaffold.Accounts

# 创建测试管理员用户
defmodule AdminScaffold.Seeds do
  def run do
    create_test_users()
    create_test_roles()
    create_test_permissions()
    create_test_menus()
    create_test_pages()
  end

  defp create_test_users do
    # 检查是否已存在管理员用户
    unless Repo.get_by(Accounts.User, email: "admin@admin.com") do
      Accounts.register_user(%{
        email: "admin@admin.com",
        # 至少12位
        password: "admin12345678",
        status: "active"
      })

      # 确认用户
      case Accounts.get_user_by_email("admin@admin.com") do
        nil ->
          IO.puts("警告: 管理员用户创建失败")

        admin ->
          {:ok, _admin} =
            AdminScaffold.Accounts.User.confirm_changeset(admin)
            |> Repo.update()

          IO.puts("✓ 管理员用户已创建并确认: admin@admin.com")
      end
    end

    # 创建测试用户
    test_users = [
      %{email: "test@example.com", password: "test12345678", status: "active"},
      %{email: "user@example.com", password: "user12345678", status: "active"}
    ]

    for user_attrs <- test_users do
      unless Repo.get_by(Accounts.User, email: user_attrs.email) do
        Accounts.register_user(user_attrs)
      end
    end
  end

  defp create_test_roles do
    alias AdminScaffold.Accounts.Role

    # 确保有管理员角色
    unless Repo.get_by(Role, name: "管理员") do
      {:ok, _role} = Accounts.create_role(%{name: "管理员", description: "系统管理员", status: 1})
      IO.puts("✓ 管理员角色已创建")
    end

    # 普通用户角色
    unless Repo.get_by(Role, name: "普通用户") do
      Accounts.create_role(%{name: "普通用户", description: "普通用户角色", status: 1})
      IO.puts("✓ 普通用户角色已创建")
    end
  end

  defp create_test_permissions do
    alias AdminScaffold.Accounts.Permission

    permissions = [
      %{name: "查看用户", slug: "user.view", description: "查看用户"},
      %{name: "创建用户", slug: "user.create", description: "创建用户"},
      %{name: "编辑用户", slug: "user.edit", description: "编辑用户"},
      %{name: "删除用户", slug: "user.delete", description: "删除用户"},
      %{name: "查看角色", slug: "role.view", description: "查看角色"},
      %{name: "编辑角色", slug: "role.edit", description: "编辑角色"},
      %{name: "查看权限", slug: "permission.view", description: "查看权限"}
    ]

    for perm_attrs <- permissions do
      unless Repo.get_by(Permission, slug: perm_attrs.slug) do
        Accounts.create_permission(perm_attrs)
        IO.puts("✓ 权限已创建: #{perm_attrs.name}")
      end
    end
  end

  defp create_test_menus do
    alias AdminScaffold.Accounts.Menu

    menus = [
      %{name: "仪表板", path: "/dashboard", icon: "dashboard", parent_id: nil, sort: 1, status: 1},
      %{name: "用户管理", path: "/admin/users", icon: "users", parent_id: nil, sort: 2, status: 1},
      %{name: "角色管理", path: "/admin/roles", icon: "roles", parent_id: nil, sort: 3, status: 1},
      %{
        name: "权限管理",
        path: "/admin/permissions",
        icon: "permissions",
        parent_id: nil,
        sort: 4,
        status: 1
      },
      %{name: "菜单管理", path: "/admin/menus", icon: "menus", parent_id: nil, sort: 5, status: 1}
    ]

    for menu_attrs <- menus do
      unless Repo.get_by(Menu, path: menu_attrs.path) do
        Accounts.create_menu(menu_attrs)
        IO.puts("✓ 菜单已创建: #{menu_attrs.name}")
      end
    end
  end

  defp create_test_pages do
    alias AdminScaffold.PageBuilder

    # 示例：创建一个产品列表页面
    unless Repo.get_by(PageBuilder.Page, slug: "products") do
      PageBuilder.create_page(%{
        name: "产品列表",
        title: "产品管理",
        slug: "products",
        type: "list",
        icon:
          "M20 7l-8-4m8 4v10l-8 4m8 4v6a2 2 0 002-2h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2h12a2 2 0 002-2V9a2 2 0 00-2-2z",
        status: "active",
        sort: 1,
        config: %{
          "title" => "产品列表",
          "columns" => [
            %{"name" => "id", "label" => "ID", "type" => "text"},
            %{"name" => "name", "label" => "产品名称", "type" => "text"},
            %{
              "name" => "status",
              "label" => "状态",
              "type" => "badge",
              "map" => %{
                "active" => %{"text" => "在售", "color" => "green"},
                "inactive" => %{"text" => "下架", "color" => "gray"}
              }
            },
            %{"name" => "price", "label" => "价格", "type" => "text"}
          ]
        }
      })
    end
  end
end

AdminScaffold.Seeds.run()
