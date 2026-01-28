defmodule AdminScaffoldWeb.PermissionLive.Index do
  use AdminScaffoldWeb, :live_view

  alias AdminScaffold.Accounts
  alias AdminScaffold.Accounts.Permission
  alias AdminScaffoldWeb.Authorization

  @impl true
  def mount(_params, _session, socket) do
    socket = Authorization.require_permission(socket, "permissions.manage")
    {:ok, stream(socket, :permissions, Accounts.list_permissions())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "编辑权限")
    |> assign(:permission, Accounts.get_permission!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "新建权限")
    |> assign(:permission, %Permission{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "权限管理")
    |> assign(:permission, nil)
  end

  @impl true
  def handle_info({AdminScaffoldWeb.PermissionLive.FormComponent, {:saved, permission}}, socket) do
    {:noreply, stream_insert(socket, :permissions, permission)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    permission = Accounts.get_permission!(id)
    {:ok, _} = Accounts.delete_permission(permission)

    {:noreply, stream_delete(socket, :permissions, permission)}
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
              配置系统权限和访问控制
              <span class="aurora-badge" style="background: rgba(16, 185, 129, 0.1); color: #10B981; margin-left: 8px;">ACL</span>
            </p>
          </div>
          <div class="flex gap-3">
            <.link navigate={~p"/dashboard"} class="aurora-btn aurora-btn-secondary">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
              </svg>
              返回
            </.link>
            <.link patch={~p"/admin/permissions/new"} class="aurora-btn aurora-btn-primary">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
              </svg>
              新建权限
            </.link>
          </div>
        </div>
      </div>
      <!-- 权限卡片网格 -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4" id="permissions" phx-update="stream">
        <div :for={{dom_id, permission} <- @streams.permissions} id={dom_id} class="aurora-card p-5">
          <!-- 权限图标 -->
          <div class="flex justify-center mb-4">
            <div class="aurora-stat-card-icon" style="background: rgba(16, 185, 129, 0.1);">
              <svg class="w-6 h-6" style="color: #10B981;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
              </svg>
            </div>
          </div>
          <!-- 权限名称 -->
          <h3 class="text-center mb-2" style="font-size: 1rem; font-weight: 600; color: var(--color-text-primary);">{permission.name}</h3>
          <!-- 权限标识 -->
          <div class="mb-3 p-2 rounded-lg text-center" style="background: var(--color-bg-muted);">
            <code style="font-size: 0.75rem; color: #10B981;">{permission.slug}</code>
          </div>
          <!-- 权限描述 -->
          <p class="text-center mb-4" style="font-size: 0.8125rem; color: var(--color-text-secondary); min-height: 2.5rem;">
            {permission.description || "暂无描述"}
          </p>
          <!-- 操作按钮 -->
          <div class="flex gap-2">
            <.link patch={~p"/admin/permissions/#{permission.id}/edit"} class="aurora-btn aurora-btn-primary flex-1" style="justify-content: center; padding: 8px 12px; font-size: 0.8125rem;">
              编辑
            </.link>
            <button phx-click="delete" phx-value-id={permission.id} data-confirm="确定要删除这个权限吗？" class="aurora-btn aurora-btn-ghost-danger" style="padding: 8px 12px; font-size: 0.8125rem;">
              删除
            </button>
          </div>
        </div>
      </div>
      <!-- 空状态 -->
      <div :if={@streams.permissions.inserts == []} class="aurora-card p-12">
        <div class="aurora-empty">
          <svg class="aurora-empty-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
          </svg>
          <p class="aurora-empty-title">暂无权限</p>
          <p class="aurora-empty-desc mb-6">点击上方"新建权限"按钮创建第一个权限</p>
          <.link patch={~p"/admin/permissions/new"} class="aurora-btn aurora-btn-primary">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
            创建权限
          </.link>
        </div>
      </div>
    </div>
    <!-- Modal for New/Edit Permission -->
    <.modal
      :if={@live_action in [:new, :edit]}
      id="permission-modal"
      show={true}
      on_cancel={JS.patch(~p"/admin/permissions")}
    >
      <.live_component
        module={AdminScaffoldWeb.PermissionLive.FormComponent}
        id={@permission.id || :new}
        title={@page_title}
        action={@live_action}
        permission={@permission}
        patch={~p"/admin/permissions"}
      />
    </.modal>
    """
  end
end
