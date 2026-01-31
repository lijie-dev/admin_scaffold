defmodule AdminScaffoldWeb.RoleLive.Index do
  use AdminScaffoldWeb, :live_view

  alias AdminScaffold.Accounts
  alias AdminScaffoldWeb.Authorization

  @impl true
  def mount(_params, _session, socket) do
    socket = Authorization.require_permission(socket, "roles.view")

    if connected?(socket) do
      {:ok, assign(socket,
        roles: Accounts.list_roles(),
        selected_roles: MapSet.new(),
        search_query: "",
        form: to_form(%{})
      )}
    else
      {:ok, assign(socket,
        roles: [],
        selected_roles: MapSet.new(),
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
    |> assign(:page_title, "角色管理")
    |> assign(:role, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "新增角色")
    |> assign(:role, %Accounts.Role{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "编辑角色")
    |> assign(:role, Accounts.get_role!(id))
  end

  @impl true
  def handle_event("save", %{"role" => role_params}, socket) do
    user_scope = socket.assigns.current_user_scope

    case Accounts.create_role(role_params, user_scope.user) do
      {:ok, _role} ->
        {:noreply,
         socket
         |> put_flash(:info, "角色创建成功")
         |> push_navigate(to: ~p"/admin/roles")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("update", %{"id" => id, "role" => role_params}, socket) do
    role = Accounts.get_role!(id)
    user_scope = socket.assigns.current_user_scope

    case Accounts.update_role(role, role_params, user_scope.user) do
      {:ok, _role} ->
        {:noreply,
         socket
         |> put_flash(:info, "角色更新成功")
         |> push_navigate(to: ~p"/admin/roles")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    role = Accounts.get_role!(id)

    case Accounts.delete_role(role) do
      {:ok, _role} ->
        {:noreply,
         socket
         |> put_flash(:info, "角色删除成功")
         |> assign(:roles, filter_roles(socket.assigns))
         |> assign(:selected_roles, MapSet.delete(socket.assigns.selected_roles, String.to_integer(id)))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "角色删除失败")}
    end
  end

  @impl true
  def handle_event("select_role", %{"id" => id}, socket) do
    role_id = String.to_integer(id)
    selected = socket.assigns.selected_roles
    new_selected = if MapSet.member?(selected, role_id) do
      MapSet.delete(selected, role_id)
    else
      MapSet.put(selected, role_id)
    end
    {:noreply, assign(socket, :selected_roles, new_selected)}
  end

  @impl true
  def handle_event("select_all", _, socket) do
    role_ids = Enum.map(socket.assigns.roles, & &1.id)
    {:noreply, assign(socket, :selected_roles, MapSet.new(role_ids))}
  end

  @impl true
  def handle_event("deselect_all", _, socket) do
    {:noreply, assign(socket, :selected_roles, MapSet.new())}
  end

  @impl true
  def handle_event("batch_delete", _, socket) do
    selected_ids = MapSet.to_list(socket.assigns.selected_roles)
    Enum.each(selected_ids, fn id ->
      role = Accounts.get_role!(id)
      Accounts.delete_role(role)
    end)

    {:noreply,
     socket
     |> put_flash(:info, "成功删除 #{length(selected_ids)} 个角色")
     |> assign(:roles, filter_roles(socket.assigns))
     |> assign(:selected_roles, MapSet.new())}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign(:roles, filter_roles(socket.assigns |> put_in([:search_query], query)))}
  end

  defp filter_roles(assigns) do
    Accounts.list_roles()
    |> filter_by_search(assigns.search_query)
  end

  defp filter_by_search(roles, ""), do: roles
  defp filter_by_search(roles, query) do
    query = String.downcase(query)
    Enum.filter(roles, fn role ->
      String.contains?(String.downcase(role.name), query) or
      String.contains?(String.downcase(role.description || ""), query)
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
            <h1 class="aurora-section-title" style="font-size: 1.5rem; margin-bottom: 0.5rem;">角色管理</h1>
            <p style="color: var(--color-text-secondary);">
              管理系统角色和权限
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
      <div :if={MapSet.size(@selected_roles) > 0} class="aurora-card p-4 mb-6" style="background: linear-gradient(135deg, #8B5CF6 0%, #A78BFA 100%); color: white;">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-3">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <span style="font-weight: 600;">已选择 {MapSet.size(@selected_roles)} 个角色</span>
          </div>
          <button phx-click="batch_delete" data-confirm="确定要删除选中的角色吗？" class="aurora-btn" style="background: rgba(239, 68, 68, 0.2); color: #FCA5A5; padding: 8px 16px; font-size: 0.875rem;">
            批量删除
          </button>
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
              placeholder="搜索角色名称或描述..."
              class="w-full px-4 py-3 rounded-lg border-2 border-gray-200 focus:border-indigo-500 focus:outline-none"
            />
            <svg class="w-5 h-5 absolute right-3 top-3 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
          </div>
        </form>
      </div>

      <!-- 角色卡片 -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div :for={role <- @roles} class="aurora-card">
          <div class="p-6">
            <div class="flex items-start justify-between mb-4">
              <div>
                <h3 class="text-xl font-bold" style="color: var(--color-text-primary);">
                  {role.name}
                </h3>
                <p style="color: var(--color-text-muted); margin-top: 0.5rem;">
                  {role.description || "暂无描述"}
                </p>
              </div>
              <input
                type="checkbox"
                checked={MapSet.member?(@selected_roles, role.id)}
                phx-click="select_role"
                phx-value-id={role.id}
                class="w-4 h-4 rounded border-2 border-gray-300"
              />
            </div>

            <div class="flex items-center gap-2 mb-4 flex-wrap">
              <span class="aurora-badge aurora-badge-secondary" style="font-size: 0.75rem;">
                {length(role.permissions)} 个权限
              </span>
              <span class="aurora-badge aurora-badge-secondary" style="font-size: 0.75rem;">
                {length(role.menus)} 个菜单
              </span>
            </div>

            <div class="flex items-center justify-between pt-4" style="border-top: 1px solid var(--color-border);">
              <div style="font-size: 0.875rem; color: var(--color-text-muted);">
                创建于 {Calendar.strftime(role.inserted_at, "%Y-%m-%d")}
              </div>
              <div class="flex items-center gap-2">
                <.link patch={~p"/admin/roles/#{role.id}/edit"} class="aurora-btn aurora-btn-primary" style="padding: 6px 12px; font-size: 0.875rem;">
                  编辑
                </.link>
                <button phx-click="delete" phx-value-id={role.id} data-confirm="确定要删除此角色吗？" class="aurora-btn aurora-btn-ghost-danger" style="padding: 6px 12px; font-size: 0.875rem;">
                  删除
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div :if={length(@roles) == 0} class="aurora-card p-12 text-center" style="color: var(--color-text-muted);">
        <svg class="w-16 h-16 mx-auto mb-4 opacity-50" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
        </svg>
        <p style="font-size: 1rem;">未找到角色</p>
        <p style="font-size: 0.875rem; margin-top: 0.5rem;">尝试调整搜索条件</p>
      </div>
    </div>
    """
  end
end
