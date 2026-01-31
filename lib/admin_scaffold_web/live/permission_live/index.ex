defmodule AdminScaffoldWeb.PermissionLive.Index do
  use AdminScaffoldWeb, :live_view

  alias AdminScaffold.Accounts
  alias AdminScaffoldWeb.Authorization

  @impl true
  def mount(_params, _session, socket) do
    socket = Authorization.require_permission(socket, "permissions.view")

    if connected?(socket) do
      {:ok, assign(socket,
        permissions: Accounts.list_permissions(),
        selected_permissions: MapSet.new(),
        search_query: "",
        form: to_form(%{})
      )}
    else
      {:ok, assign(socket,
        permissions: [],
        selected_permissions: MapSet.new(),
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
    |> assign(:page_title, "权限管理")
    |> assign(:permission, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "新增权限")
    |> assign(:permission, %Accounts.Permission{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "编辑权限")
    |> assign(:permission, Accounts.get_permission!(id))
  end

  @impl true
  def handle_event("save", %{"permission" => permission_params}, socket) do
    user_scope = socket.assigns.current_user_scope

    case Accounts.create_permission(permission_params, user_scope.user) do
      {:ok, _permission} ->
        {:noreply,
         socket
         |> put_flash(:info, "权限创建成功")
         |> push_navigate(to: ~p"/admin/permissions")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("update", %{"id" => id, "permission" => permission_params}, socket) do
    permission = Accounts.get_permission!(id)
    user_scope = socket.assigns.current_user_scope

    case Accounts.update_permission(permission, permission_params, user_scope.user) do
      {:ok, _permission} ->
        {:noreply,
         socket
         |> put_flash(:info, "权限更新成功")
         |> push_navigate(to: ~p"/admin/permissions")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    permission = Accounts.get_permission!(id)

    case Accounts.delete_permission(permission) do
      {:ok, _permission} ->
        {:noreply,
         socket
         |> put_flash(:info, "权限删除成功")
         |> assign(:permissions, filter_permissions(socket.assigns))
         |> assign(:selected_permissions, MapSet.delete(socket.assigns.selected_permissions, String.to_integer(id)))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "权限删除失败")}
    end
  end

  @impl true
  def handle_event("select_permission", %{"id" => id}, socket) do
    permission_id = String.to_integer(id)
    selected = socket.assigns.selected_permissions
    new_selected = if MapSet.member?(selected, permission_id) do
      MapSet.delete(selected, permission_id)
    else
      MapSet.put(selected, permission_id)
    end
    {:noreply, assign(socket, :selected_permissions, new_selected)}
  end

  @impl true
  def handle_event("select_all", _, socket) do
    permission_ids = Enum.map(socket.assigns.permissions, & &1.id)
    {:noreply, assign(socket, :selected_permissions, MapSet.new(permission_ids))}
  end

  @impl true
  def handle_event("deselect_all", _, socket) do
    {:noreply, assign(socket, :selected_permissions, MapSet.new())}
  end

  @impl true
  def handle_event("batch_delete", _, socket) do
    selected_ids = MapSet.to_list(socket.assigns.selected_permissions)
    Enum.each(selected_ids, fn id ->
      permission = Accounts.get_permission!(id)
      Accounts.delete_permission(permission)
    end)

    {:noreply,
     socket
     |> put_flash(:info, "成功删除 #{length(selected_ids)} 个权限")
     |> assign(:permissions, filter_permissions(socket.assigns))
     |> assign(:selected_permissions, MapSet.new())}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign(:permissions, filter_permissions(socket.assigns |> put_in([:search_query], query)))}
  end

  defp filter_permissions(assigns) do
    Accounts.list_permissions()
    |> filter_by_search(assigns.search_query)
  end

  defp filter_by_search(permissions, ""), do: permissions
  defp filter_by_search(permissions, query) do
    query = String.downcase(query)
    Enum.filter(permissions, fn permission ->
      String.contains?(String.downcase(permission.name), query) or
      String.contains?(String.downcase(permission.slug || ""), query) or
      String.contains?(String.downcase(permission.description || ""), query)
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
            <h1 class="aurora-section-title" style="font-size: 1.5rem; margin-bottom: 0.5rem;">权限管理</h1>
            <p style="color: var(--color-text-secondary);">
              管理系统权限
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
      <div :if={MapSet.size(@selected_permissions) > 0} class="aurora-card p-4 mb-6" style="background: linear-gradient(135deg, #10B981 0%, #34D399 100%); color: white;">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-3">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <span style="font-weight: 600;">已选择 {MapSet.size(@selected_permissions)} 个权限</span>
          </div>
          <button phx-click="batch_delete" data-confirm="确定要删除选中的权限吗？" class="aurora-btn" style="background: rgba(239, 68, 68, 0.2); color: #FCA5A5; padding: 8px 16px; font-size: 0.875rem;">
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
              placeholder="搜索权限名称、标识或描述..."
              class="w-full px-4 py-3 rounded-lg border-2 border-gray-200 focus:border-indigo-500 focus:outline-none"
            />
            <svg class="w-5 h-5 absolute right-3 top-3 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
          </div>
        </form>
      </div>

      <!-- 权限网格 -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
        <div :for={permission <- @permissions} class="aurora-card">
          <div class="p-4">
            <div class="flex items-start justify-between mb-3">
              <div class="flex-1">
                <h3 class="font-bold" style="color: var(--color-text-primary);">
                  {permission.name}
                </h3>
                <code style="background: var(--color-bg-muted); padding: 2px 6px; border-radius: 4px; font-size: 0.75rem; display: inline-block; margin-top: 4px;">
                  {permission.slug}
                </code>
              </div>
              <input
                type="checkbox"
                checked={MapSet.member?(@selected_permissions, permission.id)}
                phx-click="select_permission"
                phx-value-id={permission.id}
                class="w-4 h-4 rounded border-2 border-gray-300"
              />
            </div>

            <p style="color: var(--color-text-muted); font-size: 0.875rem; margin-top: 0.5rem;">
              {permission.description || "暂无描述"}
            </p>

            <div class="flex items-center justify-between pt-3 mt-3" style="border-top: 1px solid var(--color-border);">
              <div style="font-size: 0.75rem; color: var(--color-text-muted);">
                {Calendar.strftime(permission.inserted_at, "%Y-%m-%d")}
              </div>
              <div class="flex items-center gap-2">
                <.link patch={~p"/admin/permissions/#{permission.id}/edit"} class="aurora-btn aurora-btn-primary" style="padding: 4px 8px; font-size: 0.75rem;">
                  编辑
                </.link>
                <button phx-click="delete" phx-value-id={permission.id} data-confirm="确定要删除此权限吗？" class="aurora-btn aurora-btn-ghost-danger" style="padding: 4px 8px; font-size: 0.75rem;">
                  删除
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div :if={length(@permissions) == 0} class="aurora-card p-12 text-center" style="color: var(--color-text-muted);">
        <svg class="w-16 h-16 mx-auto mb-4 opacity-50" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
        </svg>
        <p style="font-size: 1rem;">未找到权限</p>
        <p style="font-size: 0.875rem; margin-top: 0.5rem;">尝试调整搜索条件</p>
      </div>
    </div>
    """
  end
end
