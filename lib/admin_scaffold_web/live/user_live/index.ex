defmodule AdminScaffoldWeb.UserLive.Index do
  use AdminScaffoldWeb, :live_view

  alias AdminScaffold.Accounts

  @impl true
  def mount(_params, _session, socket) do
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

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto">
      <!-- Header -->
      <div class="brutal-card p-8 mb-8 fade-in-stagger" style="background: var(--color-bg-card);">
        <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div class="flex-1">
            <h1 class="text-4xl font-black mb-2 text-glitch" data-text="用户管理" style="font-family: var(--font-display); color: var(--color-text-primary);">
              用户管理
            </h1>
            <p class="text-lg flex items-center gap-2" style="color: var(--color-text-secondary); font-family: var(--font-body);">
              系统中所有注册用户的列表
              <span class="px-3 py-1 brutal-btn text-xs" style="background: var(--color-accent-cyan); color: #000; font-family: var(--font-display);">
                ADMIN
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
          </div>
        </div>
      </div>

      <!-- Users Table -->
      <div class="brutal-card fade-in-stagger" style="background: var(--color-bg-card);">
        <div class="p-6 border-b-3 border-black" style="background: var(--color-bg-elevated);">
          <div class="flex items-center justify-between">
            <h2 class="text-xl font-black flex items-center gap-3" style="font-family: var(--font-display); color: var(--color-text-primary);">
              <span class="w-1 h-6" style="background: var(--color-accent-pink);"></span>
              用户列表
            </h2>
            <div class="flex items-center gap-2" style="color: var(--color-text-muted); font-family: var(--font-mono); font-size: 0.875rem;">
              <span class="w-2 h-2 rounded-full pulse-glow" style="background: var(--color-accent-green);"></span>
              实时数据
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
                <th class="text-left" style="color: var(--color-accent-pink);">
                  邮箱地址
                </th>
                <th class="text-left" style="color: var(--color-accent-purple);">
                  注册时间
                </th>
                <th class="text-right" style="color: var(--color-accent-yellow);">
                  操作
                </th>
              </tr>
            </thead>
            <tbody id="users" phx-update="stream">
              <tr :for={{dom_id, user} <- @streams.users} id={dom_id} class="group">
                <td style="color: var(--color-accent-cyan);">
                  <div class="font-bold">
                    #<%= user.id %>
                  </div>
                </td>
                <td>
                  <div class="flex items-center gap-3">
                    <div class="w-10 h-10 brutal-btn flex items-center justify-center font-bold text-black" style="background: linear-gradient(135deg, var(--color-accent-cyan), var(--color-accent-purple)); font-family: var(--font-display);">
                      <%= String.first(user.email) |> String.upcase() %>
                    </div>
                    <div>
                      <div class="font-bold" style="color: var(--color-text-primary);">
                        <%= user.email %>
                      </div>
                      <div class="text-xs" style="color: var(--color-text-muted); font-family: var(--font-mono);">
                        User Account
                      </div>
                    </div>
                  </div>
                </td>
                <td style="color: var(--color-text-secondary);">
                  <div class="flex flex-col">
                    <span class="font-bold">
                      <%= Calendar.strftime(user.inserted_at, "%Y-%m-%d") %>
                    </span>
                    <span class="text-xs" style="color: var(--color-text-muted);">
                      <%= Calendar.strftime(user.inserted_at, "%H:%M") %>
                    </span>
                  </div>
                </td>
                <td class="text-right">
                  <.link
                    navigate={~p"/admin/users/#{user}"}
                    class="brutal-btn px-4 py-2 text-white font-bold inline-flex items-center gap-2 group-hover:scale-105 transition-transform"
                    style="background: var(--color-accent-pink); font-family: var(--font-display); font-size: 0.75rem;"
                  >
                    查看详情
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                    </svg>
                  </.link>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Table Footer -->
        <div class="p-6 border-t-3 border-black flex items-center justify-between" style="background: var(--color-bg-elevated);">
          <div class="flex items-center gap-2" style="color: var(--color-text-muted); font-family: var(--font-mono); font-size: 0.875rem;">
            <svg class="w-5 h-5" style="color: var(--color-accent-cyan);" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            显示所有用户
          </div>
          <div class="brutal-btn px-4 py-2 text-black font-bold" style="background: var(--color-accent-yellow); font-family: var(--font-display); font-size: 0.75rem;">
            共 <%= length(@streams.users.inserts) %> 条记录
          </div>
        </div>
      </div>
    </div>
    """
  end
end
