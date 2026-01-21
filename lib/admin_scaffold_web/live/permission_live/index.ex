defmodule AdminScaffoldWeb.PermissionLive.Index do
  use AdminScaffoldWeb, :live_view

  alias AdminScaffold.Accounts
  alias AdminScaffold.Accounts.Permission

  @impl true
  def mount(_params, _session, socket) do
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
    <div class="max-w-7xl mx-auto">
      <!-- Header -->
      <div class="brutal-card p-8 mb-8 fade-in-stagger" style="background: var(--color-bg-card);">
        <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div class="flex-1">
            <h1 class="text-4xl font-black mb-2 text-glitch" data-text="权限管理" style="font-family: var(--font-display); color: var(--color-text-primary);">
              权限管理
            </h1>
            <p class="text-lg flex items-center gap-2" style="color: var(--color-text-secondary); font-family: var(--font-body);">
              配置系统权限和访问控制
              <span class="px-3 py-1 brutal-btn text-xs" style="background: var(--color-accent-orange); color: #000; font-family: var(--font-display);">
                ACL
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
              patch={~p"/admin/permissions/new"}
              class="brutal-btn px-6 py-3 text-white font-bold flex items-center gap-2"
              style="background: var(--color-accent-orange); font-family: var(--font-display);"
            >
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
              </svg>
              新建权限
            </.link>
          </div>
        </div>
      </div>

      <!-- Permissions Grid -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4" id="permissions" phx-update="stream">
        <div
          :for={{dom_id, permission} <- @streams.permissions}
          id={dom_id}
          class="brutal-card p-4 fade-in-stagger hover:scale-105 transition-all"
          style="background: var(--color-bg-card); border-color: var(--color-accent-orange);"
        >
          <!-- Permission Icon -->
          <div class="mb-4 flex justify-center">
            <div class="w-16 h-16 brutal-btn flex items-center justify-center" style="background: var(--color-accent-orange); color: #000;">
              <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
              </svg>
            </div>
          </div>

          <!-- Permission Name -->
          <h3 class="text-lg font-black mb-2 text-center" style="font-family: var(--font-display); color: var(--color-text-primary);">
            <%= permission.name %>
          </h3>

          <!-- Permission Slug -->
          <div class="mb-3 p-2 text-center" style="background: var(--color-bg-elevated);">
            <p class="text-xs font-bold" style="color: var(--color-accent-orange); font-family: var(--font-mono);">
              <%= permission.slug %>
            </p>
          </div>

          <!-- Permission Description -->
          <p class="text-xs mb-4 text-center min-h-[2.5rem]" style="color: var(--color-text-muted); font-family: var(--font-body);">
            <%= permission.description || "暂无描述" %>
          </p>

          <!-- Actions -->
          <div class="flex gap-2">
            <.link
              patch={~p"/admin/permissions/#{permission}/edit"}
              class="flex-1 brutal-btn px-3 py-2 text-white font-bold text-center text-xs"
              style="background: var(--color-primary); font-family: var(--font-display);"
            >
              编辑
            </.link>
            <button
              phx-click="delete"
              phx-value-id={permission.id}
              data-confirm="确定要删除这个权限吗？"
              class="brutal-btn px-3 py-2 text-white font-bold text-xs"
              style="background: var(--color-accent-pink); font-family: var(--font-display);"
            >
              删除
            </button>
          </div>
        </div>
      </div>

      <!-- Empty State -->
      <div
        :if={@streams.permissions.inserts == []}
        class="brutal-card p-12 text-center fade-in-stagger"
        style="background: var(--color-bg-card);"
      >
        <div class="w-24 h-24 mx-auto mb-6 brutal-card pattern-stripes" style="background: var(--color-accent-orange);">
          <div class="w-full h-full flex items-center justify-center">
            <svg class="w-12 h-12 text-black" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
            </svg>
          </div>
        </div>
        <h3 class="text-2xl font-black mb-2" style="font-family: var(--font-display); color: var(--color-text-primary);">
          暂无权限
        </h3>
        <p class="mb-6" style="color: var(--color-text-secondary); font-family: var(--font-body);">
          点击上方"新建权限"按钮创建第一个权限
        </p>
        <.link
          patch={~p"/admin/permissions/new"}
          class="brutal-btn px-8 py-3 text-white font-bold inline-flex items-center gap-2"
          style="background: var(--color-accent-orange); font-family: var(--font-display);"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
          </svg>
          创建权限
        </.link>
      </div>
    </div>
    """
  end
end
