defmodule AdminScaffoldWeb.RoleLive.Index do
  use AdminScaffoldWeb, :live_view

  alias AdminScaffold.Accounts
  alias AdminScaffold.Accounts.Role
  alias AdminScaffoldWeb.Authorization

  @impl true
  def mount(_params, _session, socket) do
    socket = Authorization.require_permission(socket, "roles.manage")

    roles =
      Accounts.list_roles()
      |> Enum.map(&preload_role_associations/1)

    {:ok, stream(socket, :roles, roles)}
  end

  defp preload_role_associations(role) do
    role
    |> AdminScaffold.Repo.preload(:permissions)
    |> AdminScaffold.Repo.preload(:menus)
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "编辑角色")
    |> assign(:role, Accounts.get_role!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "新建角色")
    |> assign(:role, %Role{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "角色管理")
    |> assign(:role, nil)
  end

  @impl true
  def handle_info({AdminScaffoldWeb.RoleLive.FormComponent, {:saved, role}}, socket) do
    {:noreply, stream_insert(socket, :roles, role)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    role = Accounts.get_role!(id)
    {:ok, _} = Accounts.delete_role(role)

    {:noreply, stream_delete(socket, :roles, role)}
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
              管理系统角色和权限配置
              <span class="aurora-badge" style="background: rgba(139, 92, 246, 0.1); color: #8B5CF6; margin-left: 8px;">RBAC</span>
            </p>
          </div>
          <div class="flex gap-3">
            <.link navigate={~p"/dashboard"} class="aurora-btn aurora-btn-secondary">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
              </svg>
              返回
            </.link>
            <.link patch={~p"/admin/roles/new"} class="aurora-btn aurora-btn-primary">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
              </svg>
              新建角色
            </.link>
          </div>
        </div>
      </div>
      <!-- 角色卡片网格 -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6" id="roles" phx-update="stream">
        <div :for={{dom_id, role} <- @streams.roles} id={dom_id} class="aurora-card p-6">
          <!-- 角色头部 -->
          <div class="flex items-start justify-between mb-4">
            <div class="flex items-center gap-3">
              <div class="aurora-stat-card-icon" style="background: rgba(139, 92, 246, 0.1);">
                <svg class="w-6 h-6" style="color: #8B5CF6;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                </svg>
              </div>
              <div>
                <h3 style="font-size: 1.125rem; font-weight: 600; color: var(--color-text-primary);">{role.name}</h3>
                <p style="font-size: 0.75rem; color: var(--color-text-muted);">ROLE_{String.upcase(role.name)}</p>
              </div>
            </div>
          </div>

          <!-- 描述 -->
          <div class="mb-4 p-3 rounded-lg" style="background: var(--color-bg-muted); border-left: 3px solid #6366F1;">
            <p style="font-size: 0.875rem; color: var(--color-text-secondary);">{role.description || "暂无描述"}</p>
          </div>

          <!-- 元信息 -->
          <div class="flex items-center gap-2 mb-4" style="font-size: 0.75rem; color: var(--color-text-muted);">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            {Calendar.strftime(role.inserted_at, "%Y-%m-%d")}
          </div>

          <!-- 权限和菜单数量 -->
          <div class="flex gap-2 mb-4">
            <span class="aurora-badge" style="background: rgba(99, 102, 241, 0.1); color: #6366F1;">{Enum.count(role.permissions || [])} 个权限</span>
            <span class="aurora-badge aurora-badge-success">{Enum.count(role.menus || [])} 个菜单</span>
          </div>

          <!-- 操作按钮 -->
          <div class="flex gap-2">
            <.link patch={~p"/admin/roles/#{role.id}/edit"} class="aurora-btn aurora-btn-primary flex-1" style="justify-content: center;">
              编辑
            </.link>
            <button phx-click="delete" phx-value-id={role.id} data-confirm="确定要删除这个角色吗？" class="aurora-btn aurora-btn-ghost-danger">
              删除
            </button>
          </div>
        </div>
      </div>
      <!-- 空状态 -->
      <div :if={@streams.roles.inserts == []} class="aurora-card p-12">
        <div class="aurora-empty">
          <svg class="aurora-empty-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
          </svg>
          <p class="aurora-empty-title">暂无角色</p>
          <p class="aurora-empty-desc mb-6">点击上方"新建角色"按钮创建第一个角色</p>
          <.link patch={~p"/admin/roles/new"} class="aurora-btn aurora-btn-primary">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
            创建角色
          </.link>
        </div>
      </div>
    </div>
    <!-- Modal for New/Edit Role -->
    <.modal
      :if={@live_action in [:new, :edit]}
      id="role-modal"
      show={true}
      on_cancel={JS.patch(~p"/admin/roles")}
    >
      <.live_component
        module={AdminScaffoldWeb.RoleLive.FormComponent}
        id={@role.id || :new}
        title={@page_title}
        action={@live_action}
        role={@role}
        patch={~p"/admin/roles"}
      />
    </.modal>
    """
  end
end
