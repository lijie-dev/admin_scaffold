defmodule AdminScaffoldWeb.RoleLive.Index do
  use AdminScaffoldWeb, :live_view

  alias AdminScaffold.Accounts
  alias AdminScaffold.Accounts.Role

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :roles, Accounts.list_roles())}
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
    <div class="max-w-7xl mx-auto">
      <!-- Header -->
      <div class="brutal-card p-8 mb-8 fade-in-stagger" style="background: var(--color-bg-card);">
        <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div class="flex-1">
            <h1 class="text-4xl font-black mb-2 text-glitch" data-text="角色管理" style="font-family: var(--font-display); color: var(--color-text-primary);">
              角色管理
            </h1>
            <p class="text-lg flex items-center gap-2" style="color: var(--color-text-secondary); font-family: var(--font-body);">
              管理系统角色和权限配置
              <span class="px-3 py-1 brutal-btn text-xs" style="background: var(--color-accent-purple); color: #000; font-family: var(--font-display);">
                RBAC
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
              patch={~p"/admin/roles/new"}
              class="brutal-btn px-6 py-3 text-white font-bold flex items-center gap-2"
              style="background: var(--color-accent-purple); font-family: var(--font-display);"
            >
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
              </svg>
              新建角色
            </.link>
          </div>
        </div>
      </div>

      <!-- Roles Grid -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6" id="roles" phx-update="stream">
        <div
          :for={{dom_id, role} <- @streams.roles}
          id={dom_id}
          class="brutal-card p-6 fade-in-stagger hover:scale-105 transition-all"
          style="background: var(--color-bg-card); border-color: var(--color-accent-purple);"
        >
          <!-- Role Header -->
          <div class="flex items-start justify-between mb-4">
            <div class="flex items-center gap-3">
              <div class="w-12 h-12 brutal-btn flex items-center justify-center" style="background: var(--color-accent-purple); color: #000;">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                </svg>
              </div>
              <div class="flex-1">
                <h3 class="text-xl font-black mb-1" style="font-family: var(--font-display); color: var(--color-text-primary);">
                  <%= role.name %>
                </h3>
                <p class="text-xs" style="color: var(--color-text-muted); font-family: var(--font-mono);">
                  ROLE_<%= String.upcase(role.name) %>
                </p>
              </div>
            </div>
          </div>

          <!-- Role Description -->
          <div class="mb-4 p-3 border-l-4" style="background: var(--color-bg-elevated); border-color: var(--color-accent-purple);">
            <p class="text-sm" style="color: var(--color-text-secondary); font-family: var(--font-body);">
              <%= role.description || "暂无描述" %>
            </p>
          </div>

          <!-- Role Meta -->
          <div class="flex items-center gap-4 mb-4 text-xs" style="color: var(--color-text-muted); font-family: var(--font-mono);">
            <div class="flex items-center gap-1">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <%= Calendar.strftime(role.inserted_at, "%Y-%m-%d") %>
            </div>
          </div>

          <!-- Actions -->
          <div class="flex gap-2">
            <.link
              patch={~p"/admin/roles/#{role}/edit"}
              class="flex-1 brutal-btn px-4 py-2 text-white font-bold text-center text-sm"
              style="background: var(--color-primary); font-family: var(--font-display);"
            >
              编辑
            </.link>
            <button
              phx-click="delete"
              phx-value-id={role.id}
              data-confirm="确定要删除这个角色吗？"
              class="brutal-btn px-4 py-2 text-white font-bold text-sm"
              style="background: var(--color-accent-pink); font-family: var(--font-display);"
            >
              删除
            </button>
          </div>
        </div>
      </div>

      <!-- Empty State -->
      <div
        :if={@streams.roles.inserts == []}
        class="brutal-card p-12 text-center fade-in-stagger"
        style="background: var(--color-bg-card);"
      >
        <div class="w-24 h-24 mx-auto mb-6 brutal-card pattern-stripes" style="background: var(--color-accent-purple);">
          <div class="w-full h-full flex items-center justify-center">
            <svg class="w-12 h-12 text-black" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
            </svg>
          </div>
        </div>
        <h3 class="text-2xl font-black mb-2" style="font-family: var(--font-display); color: var(--color-text-primary);">
          暂无角色
        </h3>
        <p class="mb-6" style="color: var(--color-text-secondary); font-family: var(--font-body);">
          点击上方"新建角色"按钮创建第一个角色
        </p>
        <.link
          patch={~p"/admin/roles/new"}
          class="brutal-btn px-8 py-3 text-white font-bold inline-flex items-center gap-2"
          style="background: var(--color-accent-purple); font-family: var(--font-display);"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
          </svg>
          创建角色
        </.link>
      </div>
    </div>
    """
  end
end
