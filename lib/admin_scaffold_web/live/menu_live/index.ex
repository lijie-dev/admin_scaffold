defmodule AdminScaffoldWeb.MenuLive.Index do
  use AdminScaffoldWeb, :live_view

  alias AdminScaffold.Accounts
  alias AdminScaffoldWeb.Authorization

  @impl true
  def mount(_params, _session, socket) do
    socket = Authorization.require_permission(socket, "menus.view")

    if connected?(socket) do
      {:ok, assign(socket,
        menus: Accounts.list_menus(),
        selected_menus: MapSet.new(),
        search_query: "",
        form: to_form(%{})
      )}
    else
      {:ok, assign(socket,
        menus: [],
        selected_menus: MapSet.new(),
        search_query: "",
        form: to_form(%{})
      )}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "菜单管理")
    |> assign(:menu, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "新增菜单")
    |> assign(:menu, %Accounts.Menu{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "编辑菜单")
    |> assign(:menu, Accounts.get_menu!(id))
  end

  @impl true
  def handle_event("save", %{"menu" => menu_params}, socket) do
    user_scope = socket.assigns.current_user_scope

    case Accounts.create_menu(menu_params, user_scope.user) do
      {:ok, _menu} ->
        {:noreply,
         socket
         |> put_flash(:info, "菜单创建成功")
         |> push_navigate(to: ~p"/admin/menus")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("update", %{"id" => id, "menu" => menu_params}, socket) do
    menu = Accounts.get_menu!(id)
    user_scope = socket.assigns.current_user_scope

    case Accounts.update_menu(menu, menu_params, user_scope.user) do
      {:ok, _menu} ->
        {:noreply,
         socket
         |> put_flash(:info, "菜单更新成功")
         |> push_navigate(to: ~p"/admin/menus")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    menu = Accounts.get_menu!(id)

    case Accounts.delete_menu(menu) do
      {:ok, _menu} ->
        {:noreply,
         socket
         |> put_flash(:info, "菜单删除成功")
         |> assign(:menus, filter_menus(socket.assigns))
         |> assign(:selected_menus, MapSet.delete(socket.assigns.selected_menus, String.to_integer(id)))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "菜单删除失败")}
    end
  end

  @impl true
  def handle_event("select_menu", %{"id" => id}, socket) do
    menu_id = String.to_integer(id)
    selected = socket.assigns.selected_menus
    new_selected = if MapSet.member?(selected, menu_id) do
      MapSet.delete(selected, menu_id)
    else
      MapSet.put(selected, menu_id)
    end
    {:noreply, assign(socket, :selected_menus, new_selected)}
  end

  @impl true
  def handle_event("select_all", _, socket) do
    menu_ids = Enum.map(socket.assigns.menus, & &1.id)
    {:noreply, assign(socket, :selected_menus, MapSet.new(menu_ids))}
  end

  @impl true
  def handle_event("deselect_all", _, socket) do
    {:noreply, assign(socket, :selected_menus, MapSet.new())}
  end

  @impl true
  def handle_event("batch_delete", _, socket) do
    selected_ids = MapSet.to_list(socket.assigns.selected_menus)
    Enum.each(selected_ids, fn id ->
      menu = Accounts.get_menu!(id)
      Accounts.delete_menu(menu)
    end)

    {:noreply,
     socket
     |> put_flash(:info, "成功删除 #{length(selected_ids)} 个菜单")
     |> assign(:menus, filter_menus(socket.assigns))
     |> assign(:selected_menus, MapSet.new())}
  end

  @impl true
  def handle_event("batch_update_status", %{"status" => status}, socket) do
    selected_ids = MapSet.to_list(socket.assigns.selected_menus)
    Enum.each(selected_ids, fn id ->
      menu = Accounts.get_menu!(id)
      Accounts.update_menu(menu, %{status: status}, socket.assigns.current_user_scope.user)
    end)

    {:noreply,
     socket
     |> put_flash(:info, "成功更新 #{length(selected_ids)} 个菜单的状态")
     |> assign(:menus, filter_menus(socket.assigns))
     |> assign(:selected_menus, MapSet.new())}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign(:menus, filter_menus(socket.assigns |> put_in([:search_query], query)))}
  end

  defp filter_menus(assigns) do
    Accounts.list_menus()
    |> filter_by_search(assigns.search_query)
  end

  defp filter_by_search(menus, ""), do: menus
  defp filter_by_search(menus, query) do
    query = String.downcase(query)
    Enum.filter(menus, fn menu ->
      String.contains?(String.downcase(menu.name), query) or
      String.contains?(String.downcase(menu.path || ""), query)
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="aurora-container">
      <!-- 页面头部 -->
      <div class="aurora-card p-6 mb-6">
        <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <h1 class="aurora-section-title" style="font-size: 1.5rem; margin-bottom: 0.5rem;">菜单管理</h1>
            <p style="color: var(--color-text-secondary);">
              管理系统菜单
              <span class="aurora-badge aurora-badge-primary ml-2">ADMIN</span>
            </p>
          </div>
          <.link navigate={~p"/dashboard"} class="aurora-btn aurora-btn-secondary">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
            </svg>
            返回仪表板
          </.link>
        </div>
      </div>

      <!-- 批量操作栏 -->
      <div :if={MapSet.size(@selected_menus) > 0} class="aurora-card p-4 mb-6" style="background: linear-gradient(135deg, #F59E0B 0%, #FBBF24 100%); color: white;">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-3">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <span style="font-weight: 600;">已选择 {MapSet.size(@selected_menus)} 个菜单</span>
          </div>
          <div class="flex items-center gap-2">
            <button phx-click="batch_update_status" phx-value-status="1" class="aurora-btn" style="background: white; color: #F59E0B; padding: 8px 16px; font-size: 0.875rem;">
              批量启用
            </button>
            <button phx-click="batch_update_status" phx-value-status="0" class="aurora-btn" style="background: rgba(255,255,255,0.2); color: white; padding: 8px 16px; font-size: 0.875rem;">
              批量禁用
            </button>
            <button phx-click="batch_delete" data-confirm="确定要删除选中的菜单吗？" class="aurora-btn" style="background: rgba(239, 68, 68, 0.2); color: #FCA5A5; padding: 8px 16px; font-size: 0.875rem;">
              批量删除
            </button>
          </div>
        </div>
      </div>

      <!-- 搜索框 -->
      <div class="aurora-card p-6 mb-6">
        <form phx-submit="search" phx-change="search">
          <div class="relative">
            <input
              type="text"
              name="query"
              value={@search_query}
              placeholder="搜索菜单名称或路径..."
              class="w-full px-4 py-3 rounded-lg border-2 border-gray-200 focus:border-indigo-500 focus:outline-none"
            />
            <svg class="w-5 h-5 absolute right-3 top-3 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
          </div>
        </form>
      </div>

      <!-- 菜单树 -->
      <div class="aurora-card">
        <div class="p-6" style="border-bottom: 1px solid var(--color-border);">
          <div class="flex items-center justify-between">
            <h2 class="aurora-section-title" style="font-size: 1.125rem;">
              菜单列表
              <span class="aurora-badge aurora-badge-warning ml-2">{length(@menus)} 条记录</span>
            </h2>
            <div class="flex items-center gap-2">
              <button phx-click="select_all" class="aurora-btn aurora-btn-secondary" style="font-size: 0.875rem;">
                全选
              </button>
              <button phx-click="deselect_all" class="aurora-btn aurora-btn-secondary" style="font-size: 0.875rem;">
                取消全选
              </button>
            </div>
          </div>
        </div>

        <div class="overflow-x-auto">
          <table class="aurora-table">
            <thead>
              <tr>
                <th style="width: 40px;"></th>
                <th>菜单名称</th>
                <th>路径</th>
                <th>图标</th>
                <th>排序</th>
                <th>状态</th>
                <th style="text-align: right;">操作</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={menu <- @menus} style={menu.parent_id && "background: var(--color-bg-muted);"}>
                <td>
                  <input
                    type="checkbox"
                    checked={MapSet.member?(@selected_menus, menu.id)}
                    phx-click="select_menu"
                    phx-value-id={menu.id}
                    class="w-4 h-4 rounded border-2 border-gray-300"
                  />
                </td>
                <td style="font-weight: 600; color: var(--color-text-primary);">
                  {menu.parent_id && "|— "}{menu.name}
                </td>
                <td>
                  <code style="background: var(--color-bg-muted); padding: 2px 6px; border-radius: 4px;">
                    {menu.path}
                  </code>
                </td>
                <td>
                  <span :if={menu.icon} class="aurora-badge aurora-badge-secondary">
                    {menu.icon}
                  </span>
                </td>
                <td>
                  <span class="aurora-badge" style="background: var(--color-bg-muted);">
                    {menu.sort}
                  </span>
                </td>
                <td>
                  <%= if menu.status == 1 do %>
                    <span class="aurora-badge aurora-badge-success">启用</span>
                  <% else %>
                    <span class="aurora-badge" style="background: var(--color-bg-muted); color: var(--color-text-muted);">禁用</span>
                  <% end %>
                </td>
                <td style="text-align: right;">
                  <div class="flex items-center justify-end gap-2">
                    <.link patch={~p"/admin/menus/#{menu.id}/edit"} class="aurora-btn aurora-btn-primary" style="padding: 6px 12px; font-size: 0.875rem;">
                      编辑
                    </.link>
                    <button phx-click="delete" phx-value-id={menu.id} data-confirm="确定要删除此菜单吗？" class="aurora-btn aurora-btn-ghost-danger" style="padding: 6px 12px; font-size: 0.875rem;">
                      删除
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div :if={length(@menus) == 0} class="p-12 text-center" style="color: var(--color-text-muted);">
          <svg class="w-16 h-16 mx-auto mb-4 opacity-50" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M4 6h16M4 12h16M4 18h16" />
          </svg>
          <p style="font-size: 1rem;">未找到菜单</p>
          <p style="font-size: 0.875rem; margin-top: 0.5rem;">尝试调整搜索条件</p>
        </div>
      </div>
    </div>
    """
  end
end
