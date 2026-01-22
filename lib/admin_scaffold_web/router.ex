defmodule AdminScaffoldWeb.Router do
  use AdminScaffoldWeb, :router

  import AdminScaffoldWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AdminScaffoldWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AdminScaffoldWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", AdminScaffoldWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and development tools in development
  if Application.compile_env(:admin_scaffold, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AdminScaffoldWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", AdminScaffoldWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{AdminScaffoldWeb.UserAuth, :require_authenticated}] do
      live "/dashboard", DashboardLive.Index, :index
      live "/admin/users", UserLive.Index, :index
      live "/admin/users/:id", UserLive.Show, :show
      live "/admin/users/:id/edit", UserLive.Index, :edit
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email

      # 角色管理
      live "/admin/roles", RoleLive.Index, :index
      live "/admin/roles/new", RoleLive.Index, :new
      live "/admin/roles/:id/edit", RoleLive.Index, :edit

      # 权限管理
      live "/admin/permissions", PermissionLive.Index, :index
      live "/admin/permissions/new", PermissionLive.Index, :new
      live "/admin/permissions/:id/edit", PermissionLive.Index, :edit

      # 菜单管理
      live "/admin/menus", MenuLive.Index, :index
      live "/admin/menus/new", MenuLive.Index, :new
      live "/admin/menus/:id/edit", MenuLive.Index, :edit

      # 审计日志
      live "/admin/audit-logs", AuditLogLive.Index, :index

      # 页面构建器示例
      live "/admin/page-builder/example", PageLive.Example, :index
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", AdminScaffoldWeb do
    pipe_through [:browser]

    live_session :public,
      on_mount: [{AdminScaffoldWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    post "/users/register", UserSessionController, :register
    delete "/users/log-out", UserSessionController, :delete
  end
end
