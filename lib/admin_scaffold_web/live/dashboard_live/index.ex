defmodule AdminScaffoldWeb.DashboardLive.Index do
  use AdminScaffoldWeb, :live_view

  alias AdminScaffold.Accounts

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      {:ok, load_stats(socket)}
    else
      {:ok, assign(socket, :user_count, 0)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto">
      <!-- Hero Header -->
      <div class="mb-8 brutal-card p-8 border-neon-cyan fade-in-stagger" style="background: var(--color-bg-card);">
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-5xl font-black mb-3 text-glitch" data-text="管理仪表板" style="font-family: var(--font-display); color: var(--color-text-primary);">
              管理仪表板
            </h1>
            <p class="text-lg" style="color: var(--color-text-secondary); font-family: var(--font-body);">
              欢迎回来，系统运行正常
              <span class="inline-flex items-center gap-2">
                <span class="w-3 h-3 rounded-full pulse-glow" style="background: var(--color-accent-green);"></span>
                <span style="color: var(--color-accent-green); font-family: var(--font-mono);">ONLINE</span>
              </span>
            </p>
          </div>
          <div class="hidden md:block">
            <div class="w-32 h-32 brutal-card border-neon-yellow pattern-stripes" style="background: var(--color-accent-yellow);">
              <div class="w-full h-full flex items-center justify-center">
                <svg class="w-20 h-20 text-black" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                </svg>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Stats Grid -->
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
        <!-- User Count Card -->
        <div class="brutal-card brutal-card-glow-cyan fade-in-stagger p-6" style="background: var(--color-bg-card); border-color: var(--color-accent-cyan);">
          <div class="flex items-center justify-between mb-4">
            <div class="p-3 brutal-btn" style="background: var(--color-accent-cyan); color: #000;">
              <svg class="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
              </svg>
            </div>
            <div class="text-right">
              <div class="text-5xl font-black" style="font-family: var(--font-display); color: var(--color-accent-cyan);">
                <%= @user_count %>
              </div>
            </div>
          </div>
          <div class="border-t-2 border-black pt-4">
            <p class="text-sm font-bold mb-2" style="color: var(--color-text-secondary); font-family: var(--font-display); text-transform: uppercase; letter-spacing: 0.1em;">
              用户总数
            </p>
            <.link navigate={~p"/admin/users"} class="text-sm font-bold flex items-center gap-1 hover:gap-2 transition-all" style="color: var(--color-accent-cyan); font-family: var(--font-mono);">
              查看全部 →
            </.link>
          </div>
        </div>

        <!-- System Status Card -->
        <div class="brutal-card brutal-card-glow-green fade-in-stagger p-6" style="background: var(--color-bg-card); border-color: var(--color-accent-green); box-shadow: var(--shadow-brutal), var(--glow-cyan);">
          <div class="flex items-center justify-between mb-4">
            <div class="p-3 brutal-btn" style="background: var(--color-accent-green); color: #000;">
              <svg class="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <div class="text-right">
              <div class="text-3xl font-black" style="font-family: var(--font-display); color: var(--color-accent-green);">
                100%
              </div>
            </div>
          </div>
          <div class="border-t-2 border-black pt-4">
            <p class="text-sm font-bold mb-2" style="color: var(--color-text-secondary); font-family: var(--font-display); text-transform: uppercase; letter-spacing: 0.1em;">
              系统状态
            </p>
            <p class="text-lg font-bold" style="color: var(--color-accent-green); font-family: var(--font-mono);">
              运行正常
            </p>
          </div>
        </div>

        <!-- Uptime Card -->
        <div class="brutal-card brutal-card-glow-purple fade-in-stagger p-6" style="background: var(--color-bg-card); border-color: var(--color-accent-purple); box-shadow: var(--shadow-brutal), var(--glow-purple);">
          <div class="flex items-center justify-between mb-4">
            <div class="p-3 brutal-btn" style="background: var(--color-accent-purple); color: #000;">
              <svg class="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <div class="text-right">
              <div class="text-2xl font-black" style="font-family: var(--font-mono); color: var(--color-accent-purple);">
                <%= format_uptime() %>
              </div>
            </div>
          </div>
          <div class="border-t-2 border-black pt-4">
            <p class="text-sm font-bold mb-2" style="color: var(--color-text-secondary); font-family: var(--font-display); text-transform: uppercase; letter-spacing: 0.1em;">
              运行时间
            </p>
            <p class="text-sm" style="color: var(--color-text-muted); font-family: var(--font-mono);">
              持续监控中...
            </p>
          </div>
        </div>
      </div>

      <!-- Quick Actions -->
      <div class="brutal-card p-6 fade-in-stagger" style="background: var(--color-bg-card);">
        <h2 class="text-2xl font-black mb-6 flex items-center gap-3" style="font-family: var(--font-display); color: var(--color-text-primary);">
          <span class="w-1 h-8" style="background: var(--color-accent-yellow);"></span>
          快速操作
        </h2>
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <.link
            navigate={~p"/admin/users"}
            class="brutal-btn p-6 text-white flex flex-col gap-3 hover:scale-105 transition-transform"
            style="background: var(--color-primary);"
          >
            <svg class="w-8 h-8" style="color: var(--color-accent-cyan);" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
            </svg>
            <div>
              <h3 class="text-lg font-bold mb-1" style="font-family: var(--font-display); text-transform: uppercase;">用户管理</h3>
              <p class="text-sm opacity-80" style="font-family: var(--font-body);">管理系统用户</p>
            </div>
          </.link>

          <.link
            navigate={~p"/admin/roles"}
            class="brutal-btn p-6 text-white flex flex-col gap-3 hover:scale-105 transition-transform"
            style="background: var(--color-accent-purple);"
          >
            <svg class="w-8 h-8" style="color: var(--color-accent-yellow);" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
            </svg>
            <div>
              <h3 class="text-lg font-bold mb-1" style="font-family: var(--font-display); text-transform: uppercase;">角色管理</h3>
              <p class="text-sm opacity-80" style="font-family: var(--font-body);">配置角色权限</p>
            </div>
          </.link>

          <.link
            navigate={~p"/admin/permissions"}
            class="brutal-btn p-6 text-white flex flex-col gap-3 hover:scale-105 transition-transform"
            style="background: var(--color-accent-pink);"
          >
            <svg class="w-8 h-8" style="color: var(--color-accent-cyan);" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
            </svg>
            <div>
              <h3 class="text-lg font-bold mb-1" style="font-family: var(--font-display); text-transform: uppercase;">权限管理</h3>
              <p class="text-sm opacity-80" style="font-family: var(--font-body);">管理系统权限</p>
            </div>
          </.link>

          <.link
            navigate={~p"/users/settings"}
            class="brutal-btn p-6 text-black flex flex-col gap-3 hover:scale-105 transition-transform"
            style="background: var(--color-accent-yellow);"
          >
            <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
            <div>
              <h3 class="text-lg font-bold mb-1" style="font-family: var(--font-display); text-transform: uppercase;">个人设置</h3>
              <p class="text-sm opacity-80" style="font-family: var(--font-body);">修改个人信息</p>
            </div>
          </.link>
        </div>
      </div>
    </div>
    """
  end

  defp load_stats(socket) do
    user_count = Accounts.count_users()
    assign(socket, :user_count, user_count)
  end

  defp format_uptime do
    {uptime, _} = :erlang.statistics(:wall_clock)
    seconds = div(uptime, 1000)
    hours = div(seconds, 3600)
    minutes = div(rem(seconds, 3600), 60)
    "#{hours}小时 #{minutes}分钟"
  end
end
