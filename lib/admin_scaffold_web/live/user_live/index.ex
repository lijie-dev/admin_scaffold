defmodule AdminScaffoldWeb.UserLive.Index do
  use AdminScaffoldWeb, :live_view

  alias AdminScaffold.Accounts
  alias AdminScaffoldWeb.Authorization

  @impl true
  def mount(_params, _session, socket) do
    socket = Authorization.require_permission(socket, "users.manage")
    {:ok, stream(socket, :users, Accounts.list_users())}
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
    {:noreply, stream(socket, :users, Accounts.list_users(), reset: true)}
  end

  def handle_info({AdminScaffoldWeb.UserLive.FormComponent, :closed}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)

    case Accounts.delete_user(user) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "用户删除成功")
         |> stream_delete(:users, user)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "用户删除失败")}
    end
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
      <!-- 用户表格 -->
      <div class="aurora-card">
        <div class="p-6" style="border-bottom: 1px solid var(--color-border);">
          <div class="flex items-center justify-between">
            <h2 class="aurora-section-title" style="font-size: 1.125rem;">用户列表</h2>
            <div class="flex items-center gap-2" style="color: var(--color-text-muted); font-size: 0.875rem;">
              <span class="w-2 h-2 rounded-full animate-pulse" style="background: var(--color-success);"></span>
              实时数据
            </div>
          </div>
        </div>

        <div class="overflow-x-auto">
          <table class="aurora-table">
            <thead>
              <tr>
                <th>ID</th>
                <th>邮箱地址</th>
                <th>状态</th>
                <th>注册时间</th>
                <th style="text-align: right;">操作</th>
              </tr>
            </thead>
            <tbody id="users" phx-update="stream">
              <tr :for={{dom_id, user} <- @streams.users} id={dom_id}>
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
                    <.link patch={~p"/admin/users/#{user.id}/edit"} class="aurora-btn aurora-btn-primary" style="padding: 6px 12px; font-size: 0.875rem;">
                      编辑
                    </.link>
                    <button phx-click="delete" phx-value-id={user.id} data-confirm="确定要删除此用户吗？" class="aurora-btn aurora-btn-ghost-danger" style="padding: 6px 12px; font-size: 0.875rem;">
                      删除
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="p-4 flex items-center justify-between" style="border-top: 1px solid var(--color-border); background: var(--color-bg-muted);">
          <span style="font-size: 0.875rem; color: var(--color-text-muted);">显示所有用户</span>
          <span class="aurora-badge aurora-badge-warning">共 {length(@streams.users.inserts)} 条记录</span>
        </div>
      </div>
      <!-- Edit User Modal -->
      <.modal
        :if={@live_action == :edit}
        id="user-modal"
        show={true}
        on_cancel={JS.patch(~p"/admin/users")}
      >
        <.live_component
          module={AdminScaffoldWeb.UserLive.FormComponent}
          id={@user.id}
          title={@page_title}
          action={@live_action}
          user={@user}
          patch={~p"/admin/users"}
        />
      </.modal>
    </div>
    """
  end
end
