defmodule AdminScaffoldWeb.Api.Router do
  @moduledoc """
  API 路由。

  提供 RESTful API 接口，使用 JWT 认证。
  """
  use AdminScaffoldWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug AdminScaffoldWeb.Plugs.ApiAuth
  end

  scope "/api/v1", AdminScaffoldWeb do
    pipe_through :api

    # 公开路由（无需认证）
    post "/auth/register", Api.AuthController, :register
    post "/auth/login", Api.AuthController, :login
    post "/auth/refresh", Api.AuthController, :refresh
    post "/auth/logout", Api.AuthController, :logout

    # 需要认证的路由
    get "/users", Api.UserController, :index
    get "/users/:id", Api.UserController, :show
    post "/users", Api.UserController, :create
    put "/users/:id", Api.UserController, :update
    delete "/users/:id", Api.UserController, :delete

    get "/roles", Api.RoleController, :index
    get "/roles/:id", Api.RoleController, :show
    post "/roles", Api.RoleController, :create
    put "/roles/:id", Api.RoleController, :update
    delete "/roles/:id", Api.RoleController, :delete

    get "/permissions", Api.PermissionController, :index
    get "/permissions/:id", Api.PermissionController, :show
    post "/permissions", Api.PermissionController, :create
    put "/permissions/:id", Api.PermissionController, :update
    delete "/permissions/:id", Api.PermissionController, :delete

    get "/menus", Api.MenuController, :index
    get "/menus/:id", Api.MenuController, :show
    post "/menus", Api.MenuController, :create
    put "/menus/:id", Api.MenuController, :update
    delete "/menus/:id", Api.MenuController, :delete

    get "/settings", Api.SettingController, :index
    get "/settings/:key", Api.SettingController, :show
    put "/settings/:key", Api.SettingController, :update

    get "/audit-logs", Api.AuditLogController, :index

    # 文件管理
    post "/files/upload", Api.FileController, :upload
    get "/files", Api.FileController, :index
    get "/files/:id", Api.FileController, :show
    delete "/files/:id", Api.FileController, :delete

    # 统计数据
    get "/stats/users", Api.StatsController, :users
    get "/stats/actions", Api.StatsController, :actions
    get "/stats/roles", Api.StatsController, :roles
  end
end
