defmodule AdminScaffoldWeb.UserLive.Index do
  use AdminScaffoldWeb, :live_view

  alias AdminScaffold.Accounts
  alias AdminScaffoldWeb.Authorization
  import AdminScaffoldWeb.PermissionButton

  @impl true
  def mount(_params, _session, socket) do
    socket = Authorization.require_permission(socket, "users.manage")

    if connected?(socket) do
      {:ok, assign(socket,
        users: Accounts.list_users(),
        selected_users: MapSet.new(),
        search_query: "",
        status_filter: "all",
        role_filter: "all"
      )}
    else
      {:ok, assign(socket,
        users: [],
        selected_users: MapSet.new(),
        search_query: "",
        status_filter: "all",
        role_filter: "all"
      )}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "用户列表")
    |> assign(:user, nil)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "编辑用户")
    |> assign(:user, Accounts.get_user!(id))
  end

  @impl true
  def handle_info({AdminScaffoldWeb.UserLive.FormComponent, {:saved, _user}}, socket) do
    {:noreply, stream(socket, :users, filter_users(socket.assigns), reset: true)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)

    case Accounts.delete_user(user) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "用户删除成功")
         |> assign(:users, filter_users(socket.assigns))
         |> assign(:selected_users, MapSet.delete(socket.assigns.selected_users, String.to_integer(id)))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "用户删除失败")}
    end
  end

  @impl true
  def handle_event("select_user", %{"id" => id}, socket) do
    user_id = String.to_integer(id)
    selected = socket.assigns.selected_users

    new_selected = if MapSet.member?(selected, user_id) do
      MapSet.delete(selected, user_id)
    else
      MapSet.put(selected, user_id)
    end

    {:noreply, assign(socket, :selected_users, new_selected)}
  end

  @impl true
  def handle_event("select_all", _, socket) do
    user_ids = Enum.map(socket.assigns.users, & &1.id)
    {:noreply, assign(socket, :selected_users, MapSet.new(user_ids))}
  end

  @impl true
  def handle_event("deselect_all", _, socket) do
    {:noreply, assign(socket, :selected_users, MapSet.new())}
  end

  @impl true
  def handle_event("batch_delete", _, socket) do
    selected_ids = MapSet.to_list(socket.assigns.selected_users)

    case Accounts.batch_delete_users(selected_ids) do
      {:ok, count} ->
        {:noreply,
         socket
         |> put_flash(:info, "成功删除 #{count} 个用户")
         |> assign(:users, filter_users(socket.assigns))
         |> assign(:selected_users, MapSet.new())}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "批量删除失败")}
    end
  end

  @impl true
  def handle_event("batch_update_status", %{"status" => status}, socket) do
    selected_ids = MapSet.to_list(socket.assigns.selected_users)

    case Accounts.batch_update_user_status(selected_ids, status) do
      {:ok, count} ->
        {:noreply,
         socket
         |> put_flash(:info, "成功更新 #{count} 个用户的状态")
         |> assign(:users, filter_users(socket.assigns))
         |> assign(:selected_users, MapSet.new())}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "批量更新失败")}
    end
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign(:users, filter_users(socket.assigns |> put_in([:search_query], query)))}
  end

  @impl true
  def handle_event("filter", %{"status" => status, "role" => role}, socket) do
    {:noreply,
     socket
     |> assign(:status_filter, status)
     |> assign(:role_filter, role)
     |> assign(:users, filter_users(socket.assigns |> put_in([:status_filter], status) |> put_in([:role_filter], role)))}
  end

  defp filter_users(assigns) do
    Accounts.list_users()
    |> filter_by_search(assigns.search_query)
    |> filter_by_status(assigns.status_filter)
    |> filter_by_role(assigns.role_filter)
  end

  defp filter_by_search(users, ""), do: users
  defp filter_by_search(users, query) do
    query = String.downcase(query)
    Enum.filter(users, fn user ->
      String.contains?(String.downcase(user.email), query) or
      String.contains?(Integer.to_string(user.id), query)
    end)
  end

  defp filter_by_status(users, "all"), do: users
  defp filter_by_status(users, status) do
    Enum.filter(users, &(&1.status == status))
  end

  defp filter_by_role(users, "all"), do: users
  defp filter_by_role(users, role_id) do
    role_id_int = String.to_integer(role_id)
    Enum.filter(users, fn user ->
      Enum.any?(user.roles, &(&1.id == role_id_int))
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
            <h1 class="aurora-section-title" style="font-size: 1.5rem; margin-bottom: 0.5rem;">用户管理</h1>
            <p style="color: var(--color-text-secondary);">
              系统中所有注册用户的列表
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
      <div :if={MapSet.size(@selected_users) > 0} class="aurora-card p-4 mb-6" style="background: linear-gradient(135deg, #6366F1 0%, #8B5CF6 100%); color: white;">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-3">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <span style="font-weight: 600;">已选择 {MapSet.size(@selected_users)} 个用户</span>
          </div>
          <div class="flex items-center gap-2">
            <button phx-click="batch_update_status" phx-value-status="active" class="aurora-btn" style="background: white; color: #6366F1; padding: 8px 16px; font-size: 0.875rem;">
              批量启用
            </button>
            <button phx-click="batch_update_status" phx-value-status="inactive" class="aurora-btn" style="background: rgba(255,255,255,0.2); color: white; padding: 8px 16px; font-size: 0.875rem;">
              批量禁用
            </button>
            <button phx-click="batch_delete" data-confirm="确定要删除选中的用户吗？" class="aurora-btn" style="background: rgba(239, 68, 68, 0.2); color: #FCA5A5; padding: 8px 16px; font-size: 0.875rem;">
              批量删除
            </button>
          </div>
        </div>
      </div>

      <!-- 搜索和筛选 -->
      <div class="aurora-card p-6 mb-6">
        <div class="flex flex-col md:flex-row gap-4">
          <!-- 搜索框 -->
          <div class="flex-1">
            <form phx-submit="search" phx-change="search">
              <div class="relative">
                <input
                  type="text"
                  name="query"
                  value={@search_query}
                  placeholder="搜索用户邮箱或 ID..."
                  class="w-full px-4 py-3 rounded-lg border-2 border-gray-200 focus:border-indigo-500 focus:outline-none"
                />
                <svg class="w-5 h-5 absolute right-3 top-3 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
              </div>
            </form>
          </div>

          <!-- 状态筛选 -->
          <div>
            <select name="status" class="px-4 py-3 rounded-lg border-2 border-gray-200 focus:border-indigo-500 focus:outline-none">
              <option value="all" selected={@status_filter == "all"}>所有状态</option>
              <option value="active" selected={@status_filter == "active"}>启用</option>
              <option value="inactive" selected={@status_filter == "inactive"}>禁用</option>
            </select>
          </div>

          <!-- 角色筛选 -->
          <div>
            <select name="role" class="px-4 py-3 rounded-lg border-2 border-gray-200 focus:border-indigo-500 focus:outline-none">
              <option value="all" selected={@role_filter == "all"}>所有角色</option>
              <option :for={role <- Accounts.list_roles()} value={role.id} selected={@role_filter == Integer.to_string(role.id)}>
                {role.name}
              </option>
            </select>
          </div>
        </div>
      </div>

      <!-- 用户表格 -->
      <div class="aurora-card">
        <div class="p-6" style="border-bottom: 1px solid var(--color-border);">
          <div class="flex items-center justify-between">
            <h2 class="aurora-section-title" style="font-size: 1.125rem;">
              用户列表
              <span class="aurora-badge aurora-badge-warning ml-2">{length(@users)} 条记录</span>
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
                <th>ID</th>
                <th>邮箱地址</th>
                <th>角色</th>
                <th>状态</th>
                <th>注册时间</th>
                <th style="text-align: right;">操作</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={user <- @users}>
                <td>
                  <input
                    type="checkbox"
                    checked={MapSet.member?(@selected_users, user.id)}
                    phx-click="select_user"
                    phx-value-id={user.id}
                    class="w-4 h-4 rounded border-2 border-gray-300"
                  />
                </td>
                <td style="color: #6366F1; font-weight: 600;">
                  #{user.id}
                </td>
                <td>
                  <div class="flex items-center gap-3">
                    <div class="aurora-avatar aurora-avatar-sm">
                      {String.first(user.email) |> String.upcase()}
                    </div>
                    <div>
                      <div style="font-weight: 600; color: var(--color-text-primary);">{user.email}</div>
                      <div style="font-size: 0.75rem; color: var(--color-text-muted);">用户账户</div>
                    </div>
                  </div>
                </td>
                <td>
                  <div class="flex items-center gap-1 flex-wrap">
                    <span :for={role <- user.roles} class="aurora-badge aurora-badge-secondary" style="font-size: 0.75rem;">
                      {role.name}
                    </span>
                  </div>
                </td>
                <td>
                  <%= if user.status == "active" do %>
                    <span class="aurora-badge aurora-badge-success">启用</span>
                  <% else %>
                    <span class="aurora-badge" style="background: var(--color-bg-muted); color: var(--color-text-muted);">禁用</span>
                  <% end %>
                </td>
                <td>
                  <div style="font-weight: 500;">{Calendar.strftime(user.inserted_at, "%Y-%m-%d")}</div>
                  <div style="font-size: 0.75rem; color: var(--color-text-muted);">{Calendar.strftime(user.inserted_at, "%H:%M")}</div>
                </td>
                <td style="text-align: right;">
                  <div class="flex items-center justify-end gap-2">
                    <.permission_button
                      socket={@socket}
                      permission="users.edit"
                      patch={~p"/admin/users/#{user.id}/edit"}
                      class="aurora-btn aurora-btn-primary"
                      style="padding: 6px 12px; font-size: 0.875rem;"
                    >
                      编辑
                    </.permission_button>
                    <.permission_button
                      socket={@socket}
                      permission="users.delete"
                      phx-click="delete"
                      phx-value-id={user.id}
                      data-confirm="确定要删除此用户吗？"
                      class="aurora-btn aurora-btn-ghost-danger"
                      style="padding: 6px 12px; font-size: 0.875rem;"
                    >
                      删除
                    </.permission_button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div :if={length(@users) == 0} class="p-12 text-center" style="color: var(--color-text-muted);">
          <svg class="w-16 h-16 mx-auto mb-4 opacity-50" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
          </svg>
          <p style="font-size: 1rem;">未找到用户</p>
          <p style="font-size: 0.875rem; margin-top: 0.5rem;">尝试调整搜索条件</p>
        </div>
      </div>

      <!-- Edit User Modal -->
      <.modal
        :if={@live_action == :edit}
        id="user-modal"
        show
        on_cancel={JS.navigate(~p"/admin/users")}
      >
        <.live_component
          module={AdminScaffoldWeb.UserLive.FormComponent}
          id={@user.id}
          title="编辑用户"
          action={@live_action}
          user={@user}
          patch={~p"/admin/users"}
        />
      </.modal>
    </div>
    """
  end
end
