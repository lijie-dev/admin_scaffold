defmodule AdminScaffoldWeb.MenuLive.Index do
  use AdminScaffoldWeb, :live_view

  alias AdminScaffold.Accounts
  alias AdminScaffold.Accounts.Menu
  alias AdminScaffoldWeb.Authorization

  @impl true
  def mount(_params, _session, socket) do
    socket = Authorization.require_permission(socket, "menus.manage")

    if connected?(socket) do
      {:ok, stream(socket, :menus, Accounts.list_menus())}
    else
      {:ok, stream(socket, :menus, [])}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "编辑菜单")
    |> assign(:menu, Accounts.get_menu!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "新建菜单")
    |> assign(:menu, %Menu{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "菜单管理")
    |> assign(:menu, nil)
  end

  @impl true
  def handle_info({AdminScaffoldWeb.MenuLive.FormComponent, {:saved, menu}}, socket) do
    {:noreply, stream_insert(socket, :menus, menu)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    menu = Accounts.get_menu!(id)
    {:ok, _} = Accounts.delete_menu(menu)

    {:noreply, stream_delete(socket, :menus, menu)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto">
      <!-- Header -->
      <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-8 mb-8">
        <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div class="flex-1">
            <h1 class="text-4xl font-bold mb-2 text-slate-900">菜单管理</h1>
            
            <p class="text-lg flex items-center gap-2 text-slate-600">
              管理系统导航菜单结构
              <span class="px-3 py-1 bg-green-100 text-green-700 text-xs font-medium rounded">
                MENU
              </span>
            </p>
          </div>
          
          <div class="flex gap-3">
            <.link
              navigate={~p"/dashboard"}
              class="px-6 py-3 bg-slate-100 hover:bg-slate-200 text-slate-700 font-medium rounded-lg flex items-center gap-2 transition-colors"
            >
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M10 19l-7-7m0 0l7-7m-7 7h18"
                />
              </svg>
              返回仪表板
            </.link>
            <.link
              patch={~p"/admin/menus/new"}
              class="px-6 py-3 bg-green-600 hover:bg-green-700 text-white font-medium rounded-lg flex items-center gap-2 transition-colors"
            >
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 4v16m8-8H4"
                />
              </svg>
              新建菜单
            </.link>
          </div>
        </div>
      </div>
      <!-- Menus Table -->
      <div class="bg-white rounded-xl shadow-sm border border-slate-200">
        <div class="p-6 border-b border-slate-200">
          <div class="flex items-center justify-between">
            <h2 class="text-xl font-semibold flex items-center gap-3 text-slate-900">
              <span class="w-1 h-6 bg-green-600"></span> 菜单列表
            </h2>
            
            <div class="flex items-center gap-2 text-slate-500 text-sm font-mono">
              <span class="w-2 h-2 rounded-full bg-green-600"></span> 树形结构
            </div>
          </div>
        </div>
        
        <div class="overflow-x-auto">
          <table class="min-w-full">
            <thead class="bg-slate-50 border-b border-slate-200">
              <tr>
                <th class="text-left px-6 py-3 text-sm font-semibold text-slate-700">ID</th>
                
                <th class="text-left px-6 py-3 text-sm font-semibold text-slate-700">菜单名称</th>
                
                <th class="text-left px-6 py-3 text-sm font-semibold text-slate-700">路径</th>
                
                <th class="text-left px-6 py-3 text-sm font-semibold text-slate-700">图标</th>
                
                <th class="text-left px-6 py-3 text-sm font-semibold text-slate-700">排序</th>
                
                <th class="text-left px-6 py-3 text-sm font-semibold text-slate-700">状态</th>
                
                <th class="text-right px-6 py-3 text-sm font-semibold text-slate-700">操作</th>
              </tr>
            </thead>
            
            <tbody id="menus" phx-update="stream">
              <tr
                :for={{dom_id, menu} <- @streams.menus}
                id={dom_id}
                class="group border-b border-slate-200 hover:bg-slate-50"
              >
                <td class="px-6 py-4 text-sm font-semibold text-slate-900">#{menu.id}</td>
                
                <td class="px-6 py-4">
                  <div class="flex items-center gap-3">
                    <div class="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center">
                      <svg
                        class="w-5 h-5 text-green-600"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M4 6h16M4 12h16M4 18h16"
                        />
                      </svg>
                    </div>
                    
                    <div>
                      <div class="font-semibold text-slate-900">{menu.name}</div>
                      
                      <div class="text-xs text-slate-500 font-mono">
                        {if menu.parent_id, do: "子菜单", else: "顶级菜单"}
                      </div>
                    </div>
                  </div>
                </td>
                
                <td class="px-6 py-4 text-sm text-slate-600">
                  <code class="font-mono text-pink-600">{menu.path}</code>
                </td>
                
                <td class="px-6 py-4 text-sm text-slate-600">
                  <span class="font-mono">{menu.icon || "-"}</span>
                </td>
                
                <td class="px-6 py-4">
                  <div class="px-2 py-1 text-xs font-semibold text-slate-900 bg-yellow-100 rounded inline-block">
                    {menu.sort}
                  </div>
                </td>
                
                <td class="px-6 py-4">
                  <div class={
                    if menu.status == 1,
                      do:
                        "px-2 py-1 text-xs font-semibold text-green-700 bg-green-100 rounded inline-block",
                      else:
                        "px-2 py-1 text-xs font-semibold text-slate-600 bg-slate-100 rounded inline-block"
                  }>
                    {if menu.status == 1, do: "启用", else: "禁用"}
                  </div>
                </td>
                
                <td class="px-6 py-4 text-right">
                  <div class="flex gap-2 justify-end">
                    <.link
                      patch={~p"/admin/menus/#{menu.id}/edit"}
                      class="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white font-medium text-xs rounded-lg transition-colors"
                    >
                      编辑
                    </.link>
                    <button
                      phx-click="delete"
                      phx-value-id={menu.id}
                      data-confirm="确定要删除这个菜单吗？"
                      class="px-4 py-2 bg-pink-600 hover:bg-pink-700 text-white font-medium text-xs rounded-lg transition-colors"
                    >
                      删除
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <!-- Table Footer -->
        <div class="p-6 border-t border-slate-200 flex items-center justify-between bg-slate-50">
          <div class="flex items-center gap-2 text-slate-500 text-sm font-mono">
            <svg class="w-5 h-5 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
            按排序字段升序显示
          </div>
          
          <div class="px-4 py-2 text-slate-900 font-semibold text-sm bg-green-100 rounded-lg">
            共 {length(@streams.menus.inserts)} 条记录
          </div>
        </div>
      </div>
    </div>
    <!-- Modal for New/Edit Menu -->
    <.modal
      :if={@live_action in [:new, :edit]}
      id="menu-modal"
      show={true}
      on_cancel={JS.patch(~p"/admin/menus")}
    >
      <.live_component
        module={AdminScaffoldWeb.MenuLive.FormComponent}
        id={@menu.id || :new}
        title={@page_title}
        action={@live_action}
        menu={@menu}
        patch={~p"/admin/menus"}
      />
    </.modal>
    """
  end
end
