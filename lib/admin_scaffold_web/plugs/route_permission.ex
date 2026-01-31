defmodule AdminScaffoldWeb.Plugs.RoutePermission do
  @moduledoc """
  路由级权限验证插件。

  检查当前用户是否具有访问特定路由的权限。
  """
  use AdminScaffoldWeb, :controller
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    user = conn.assigns.current_user

    # 管理员跳过权限检查
    if user && is_admin?(user) do
      conn
    else
      check_route_permission(conn)
    end
  end

  # 检查路由权限
  defp check_route_permission(conn) do
    request_path = conn.request_path
    user = conn.assigns.current_user

    cond do
      # 未登录用户
      is_nil(user) ->
        redirect_to_login(conn)

      # 已登录但无权限
      !has_route_permission?(user, request_path) ->
        conn
        |> put_flash(:error, "您没有权限访问此页面")
        |> redirect(to: ~p"/dashboard")

      # 有权限
      true ->
        conn
    end
  end

  # 检查用户是否为管理员
  defp is_admin?(user) do
    Enum.any?(user.roles, &(&1.name == "admin"))
  end

  # 检查用户是否有路由访问权限
  defp has_route_permission?(user, request_path) do
    # 获取用户的所有权限
    permissions = get_user_permissions(user)

    # 定义路由到权限的映射
    route_permission_map = %{
      "/admin/users" => "users.view",
      "/admin/users/:id" => "users.view",
      "/admin/users/:id/edit" => "users.edit",
      "/admin/roles" => "roles.view",
      "/admin/roles/:id/edit" => "roles.edit",
      "/admin/permissions" => "permissions.view",
      "/admin/permissions/:id/edit" => "permissions.edit",
      "/admin/menus" => "menus.view",
      "/admin/menus/:id/edit" => "menus.edit",
      "/admin/settings" => "settings.view",
      "/admin/settings/:id/edit" => "settings.edit",
      "/admin/audit-logs" => "audit_logs.view"
    }

    # 匹配路由模式
    matched_permission = Enum.find(route_permission_map, fn {route_pattern, _} ->
      match_route?(route_pattern, request_path)
    end)

    case matched_permission do
      {_, permission} -> permission in permissions
      nil -> true  # 未定义的路由默认允许
    end
  end

  # 简单的路由匹配
  defp match_route?(pattern, path) do
    pattern_parts = String.split(pattern, "/")
    path_parts = String.split(path, "/")

    Enum.zip_with(pattern_parts, path_parts, fn
      (":id", _) -> true
      (a, b) -> a == b
    end)
    |> Enum.all?()
    |> Kernel.&&(length(pattern_parts) == length(path_parts))
  end

  # 获取用户的所有权限
  defp get_user_permissions(user) do
    Enum.flat_map(user.roles, fn role ->
      Enum.map(role.permissions, & &1.name)
    end)
    |> Enum.uniq()
  end

  # 重定向到登录页
  defp redirect_to_login(conn) do
    conn
    |> put_flash(:error, "请先登录")
    |> redirect(to: ~p"/users/log-in")
    |> halt()
  end
end
