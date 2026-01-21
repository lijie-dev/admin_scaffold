defmodule AdminScaffoldWeb.MenuLive.Index do
  use AdminScaffoldWeb, :live_view

  alias AdminScaffold.Accounts
  alias AdminScaffold.Accounts.Menu

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :menus, Accounts.list_menus())}
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
      <div class="brutal-card p-8 mb-8 fade-in-stagger" style="background: var(--color-bg-card);">
        <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div class="flex-1">
            <h1 class="text-4xl font-black mb-2 text-glitch" data-text="菜单管理" style="font-family: var(--font-display); color: var(--color-text-primary);">
              菜单管理
            </h1>
            <p class="text-lg flex items-center gap-2" style="color: var(--color-text-secondary); font-family: var(--font-body);">
              管理系统导航菜单结构
              <span class="px-3 py-1 brutal-btn text-xs" style="background: var(--color-accent-green); color: #000; font-family: var(--font-display);">
                MENU
              </span>
            </p>
          </div>
          <div class="flex gap-3">
            <.link
              navigate={~p"/dashboard"}
              class="brutal-btn px-6 py-3 text-white font-bold flex items-center gap-2"
              style="background: var(--color-bg-elevated); font-family: var(--font-display);"
            >
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
              </svg>
              返回仪表板
            </.link>
            <.link
              patch={~p"/admin/menus/new"}
              class="brutal-btn px-6 py-3 text-white font-bold flex items-center gap-2"
              style="background: var(--color-accent-green); font-family: var(--font-display);"
            >
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
              </svg>
              新建菜单
            </.link>
          </div>
        </div>
      </div>

      <!-- Menus Table -->
      <div class="brutal-card fade-in-stagger" style="background: var(--color-bg-card);">
        <div class="p-6 border-b-3 border-black" style="background: var(--color-bg-elevated);">
          <div class="flex items-center justify-between">
            <h2 class="text-xl font-black flex items-center gap-3" style="font-family: var(--font-display); color: var(--color-text-primary);">
              <span class="w-1 h-6" style="background: var(--color-accent-green);"></span>
              菜单列表
            </h2>
            <div class="flex items-center gap-2" style="color: var(--color-text-muted); font-family: var(--font-mono); font-size: 0.875rem;">
              <span class="w-2 h-2 rounded-full pulse-glow" style="background: var(--color-accent-green);"></span>
              树形结构
            </div>
          </div>
        </div>

        <div class="overflow-x-auto">
          <table class="min-w-full brutal-table">
            <thead>
              <tr>
                <th class="text-left" style="color: var(--color-accent-cyan);">
                  ID
                </th>
                <th class="text-left" style="color: var(--color-accent-green);">
                  菜单名称
                </th>
                <th class="text-left" style="color: var(--color-accent-pink);">
                  路径
                </th>
                <th class="text-left" style="color: var(--color-accent-purple);">
                  图标
                </th>
                <th class="text-left" style="color: var(--color-accent-yellow);">
                  排序
                </th>
                <th class="text-left" style="color: var(--color-accent-orange);">
                  状态
                </th>
                <th class="text-right" style="color: var(--color-text-primary);">
                  操作
                </th>
              </tr>
            </thead>
            <tbody id="menus" phx-update="stream">
              <tr :for={{dom_id, menu} <- @streams.menus} id={dom_id} class="group">
                <td style="color: var(--color-accent-cyan);">
                  <div class="font-bold">
                    #<%= menu.id %>
                  </div>
                </td>
                <td>
                  <div class="flex items-center gap-3">
                    <div class="w-10 h-10 brutal-btn flex items-center justify-center" style="background: var(--color-accent-green); color: #000;">
                      <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
                      </svg>
                    </div>
                    <div>
                      <div class="font-bold" style="color: var(--color-text-primary);">
                        <%= menu.name %>
                      </div>
                      <div class="text-xs" style="color: var(--color-text-muted); font-family: var(--font-mono);">
                        <%= if menu.parent_id, do: "子菜单", else: "顶级菜单" %>
                      </div>
                    </div>
                  </div>
                </td>
                <td style="color: var(--color-text-secondary);">
                  <code class="text-sm" style="font-family: var(--font-mono); color: var(--color-accent-pink);">
                    <%= menu.path %>
                  </code>
                </td>
                <td style="color: var(--color-text-secondary);">
                  <span class="text-sm" style="font-family: var(--font-mono);">
                    <%= menu.icon || "-" %>
                  </span>
                </td>
                <td>
                  <div class="brutal-btn px-2 py-1 text-xs font-bold text-black" style="background: var(--color-accent-yellow); font-family: var(--font-display);">
                    <%= menu.sort %>
                  </div>
                </td>
                <td>
                  <div class={"brutal-btn px-2 py-1 text-xs font-bold text-black #{if menu.status == 1, do: "", else: ""}"} style={"background: #{if menu.status == 1, do: "var(--color-accent-green)", else: "var(--color-text-muted)"}; font-family: var(--font-display);"}>
                    <%= if menu.status == 1, do: "启用", else: "禁用" %>
                  </div>
                </td>
                <td class="text-right">
                  <div class="flex gap-2 justify-end">
                    <.link
                      patch={~p"/admin/menus/#{menu}/edit"}
                      class="brutal-btn px-4 py-2 text-white font-bold text-xs"
                      style="background: var(--color-primary); font-family: var(--font-display);"
                    >
                      编辑
                    </.link>
                    <button
                      phx-click="delete"
                      phx-value-id={menu.id}
                      data-confirm="确定要删除这个菜单吗？"
                      class="brutal-btn px-4 py-2 text-white font-bold text-xs"
                      style="background: var(--color-accent-pink); font-family: var(--font-display);"
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
        <div class="p-6 border-t-3 border-black flex items-center justify-between" style="background: var(--color-bg-elevated);">
          <div class="flex items-center gap-2" style="color: var(--color-text-muted); font-family: var(--font-mono); font-size: 0.875rem;">
            <svg class="w-5 h-5" style="color: var(--color-accent-green);" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            按排序字段升序显示
          </div>
          <div class="brutal-btn px-4 py-2 text-black font-bold" style="background: var(--color-accent-green); font-family: var(--font-display); font-size: 0.75rem;">
            共 <%= length(@streams.menus.inserts) %> 条记录
          </div>
        </div>
      </div>
    </div>
    """
  end
end
