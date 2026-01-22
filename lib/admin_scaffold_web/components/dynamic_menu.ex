defmodule AdminScaffoldWeb.Components.DynamicMenu do
  @moduledoc """
  动态菜单渲染组件

  从数据库加载菜单配置并渲染导航菜单
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS

  @doc """
  渲染侧边栏导航菜单

  ## 参数
    - current_user: 当前用户
    - current_path: 当前路径
  """
  attr :current_user, :map, required: true
  attr :current_path, :string, required: true
  attr :rest, :global

  def sidebar_menu(assigns) do
    ~H"""
    <nav class="space-y-1">
      <%= for menu <- get_user_menus(@current_user) do %>
        <.menu_item menu={menu} current_path={@current_path} level={0} />
      <% end %>
    </nav>
    """
  end

  @doc """
  渲染单个菜单项
  """
  attr :menu, :map, required: true
  attr :current_path, :string, required: true
  attr :level, :integer, default: 0

  def menu_item(assigns) do
    assigns =
      assign(assigns, :is_active, String.starts_with?(assigns.current_path, assigns.menu.path))

    ~H"""
    <div>
      <%= if @menu.children && length(@menu.children) > 0 do %>
        <.submenu menu={@menu} current_path={@current_path} level={@level} is_active={@is_active} />
      <% else %>
        <.link
          navigate={@menu.path}
          class={[
            "group flex items-center px-2 py-2 text-sm font-medium rounded-md w-full transition-colors",
            @level > 0 && "ml-#{@level * 4}",
            @is_active && "bg-blue-50 text-blue-700",
            !@is_active && "text-slate-700 hover:bg-slate-50 hover:text-slate-900"
          ]}
        >
          <%= if @menu.icon do %>
            <svg
              class={["mr-3 flex-shrink-0 h-6 w-6", @is_active && "text-blue-500"]}
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d={icon_path(@menu.icon)}
              />
            </svg>
          <% end %>
           <span class="flex-1">{@menu.name}</span>
        </.link>
      <% end %>
    </div>
    """
  end

  @doc """
  渲染子菜单
  """
  attr :menu, :map, required: true
  attr :current_path, :string, required: true
  attr :level, :integer, default: 0
  attr :is_active, :boolean, default: false

  def submenu(assigns) do
    ~H"""
    <div class="space-y-1">
      <button
        phx-click={toggle_submenu(@menu.id)}
        class={[
          "group flex items-center px-2 py-2 text-sm font-medium rounded-md w-full transition-colors",
          @level > 0 && "ml-#{@level * 4}",
          @is_active && "bg-blue-50 text-blue-700",
          !@is_active && "text-slate-700 hover:bg-slate-50 hover:text-slate-900"
        ]}
      >
        <%= if @menu.icon do %>
          <svg
            class={["mr-3 flex-shrink-0 h-6 w-6", @is_active && "text-blue-500"]}
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d={icon_path(@menu.icon)}
            />
          </svg>
        <% end %>
         <span class="flex-1 text-left">{@menu.name}</span>
        <svg
          id={"chevron-#{@menu.id}"}
          class="ml-3 h-5 w-5 transform transition-transform submenu-chevron-#{@menu.id}"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
        </svg>
      </button>
      <div
        id={"submenu-#{@menu.id}"}
        class="hidden space-y-1 mt-1"
      >
        <%= for child <- @menu.children do %>
          <.menu_item menu={child} current_path={@current_path} level={@level + 1} />
        <% end %>
      </div>
    </div>
    """
  end

  @doc """
  渲染顶部导航栏
  """
  attr :current_user, :map, required: true
  attr :rest, :global

  def top_navigation(assigns) do
    ~H"""
    <nav class="bg-white shadow-sm border-b border-slate-200">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-16">
          <div class="flex">
            <div class="flex-shrink-0 flex items-center">
              <h1 class="text-xl font-bold text-slate-900">Admin Scaffold</h1>
            </div>
            
            <div class="hidden sm:ml-8 sm:flex sm:space-x-8">
              <%= for menu <- get_top_menus(@current_user) do %>
                <.link
                  navigate={menu.path}
                  class="inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium transition-colors border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300"
                >
                  {menu.name}
                </.link>
              <% end %>
            </div>
          </div>
          
          <div class="flex items-center">
            <div class="ml-3 relative">
              <div>
                <button
                  type="button"
                  class="flex text-sm border-2 border-transparent rounded-full focus:outline-none focus:border-blue-300 transition-colors"
                  id="user-menu-button"
                  phx-click={toggle_dropdown("user-menu-dropdown")}
                >
                  <span class="sr-only">打开用户菜单</span>
                  <div class="h-8 w-8 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center text-white font-bold">
                    {String.first(@current_user.email) |> String.upcase()}
                  </div>
                </button>
              </div>
              
              <div
                id="user-menu-dropdown"
                phx-clickaway={hide_dropdown("user-menu-dropdown")}
                class="hidden origin-top-right absolute right-0 mt-2 w-48 rounded-md shadow-lg py-1 bg-white ring-1 ring-black ring-opacity-5 focus:outline-none z-50"
              >
                <.link
                  navigate="/users/settings"
                  class="block px-4 py-2 text-sm text-slate-700 hover:bg-slate-100"
                >
                  个人设置
                </.link>
                <.link
                  navigate="/users/log-out"
                  method="delete"
                  class="block px-4 py-2 text-sm text-slate-700 hover:bg-slate-100"
                >
                  退出登录
                </.link>
              </div>
            </div>
          </div>
        </div>
      </div>
    </nav>
    """
  end

  # JavaScript 命令

  defp toggle_submenu(id) do
    %JS{}
    |> JS.toggle(
      to: "##{id}",
      in: {"block", "opacity-100", "hidden", "opacity-0"},
      out: {"hidden", "opacity-0", "block", "opacity-100"}
    )
    |> JS.toggle(
      to: "#chevron-#{id}",
      in: {"rotate-180"},
      out: {"rotate-0"}
    )
  end

  defp toggle_dropdown(id) do
    JS.toggle(
      to: "##{id}",
      in: {"block", "opacity-100", "transform scale-100"},
      out: {"hidden", "opacity-0", "transform scale-95"}
    )
  end

  defp hide_dropdown(id) do
    JS.hide(
      to: "##{id}",
      transition: {"hidden", "opacity-0", "transform scale-95"}
    )
  end

  # 辅助函数

  defp get_user_menus(_user) do
    # 获取用户有权访问的菜单
    # 这里暂时返回固定菜单，后续可以从数据库加载
    [
      %{
        id: "dashboard",
        name: "仪表板",
        path: "/dashboard",
        icon:
          "M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2H5a2 2 0 00-2-2z M3 7V5a2 2 0 012-2h14a2 2 0 012 2v2",
        children: []
      },
      %{
        id: "system",
        name: "系统管理",
        path: "#",
        icon:
          "M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z",
        children: [
          %{id: "users", name: "用户管理", path: "/admin/users", icon: nil, children: []},
          %{id: "roles", name: "角色管理", path: "/admin/roles", icon: nil, children: []},
          %{id: "permissions", name: "权限管理", path: "/admin/permissions", icon: nil, children: []},
          %{id: "menus", name: "菜单管理", path: "/admin/menus", icon: nil, children: []}
        ]
      }
    ]
  end

  defp get_top_menus(_user) do
    # 顶部导航菜单
    []
  end

  defp icon_path(icon_string) do
    # 如果 icon 是完整的 SVG path，直接返回
    # 否则返回默认路径
    if String.contains?(icon_string, "M") do
      icon_string
    else
      "M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2H5a2 2 0 00-2-2z"
    end
  end
end
