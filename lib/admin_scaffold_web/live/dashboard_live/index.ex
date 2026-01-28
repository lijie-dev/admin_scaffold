defmodule AdminScaffoldWeb.DashboardLive.Index do
  use AdminScaffoldWeb, :live_view

  alias AdminScaffold.Accounts
  alias AdminScaffold.System

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      {:ok, load_stats(socket)}
    else
      {:ok,
       assign(socket,
         user_count: 0,
         role_count: 0,
         permission_count: 0,
         today_actions: 0,
         chart_data: []
       )}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="aurora-container">
      <!-- 欢迎区域 -->
      <div class="aurora-card p-8 mb-8" style="background: linear-gradient(135deg, #6366F1 0%, #8B5CF6 100%); color: white;">
        <div class="flex items-center justify-between">
          <div>
            <h1 style="font-size: 2rem; font-weight: 700; margin-bottom: 0.5rem;">
              管理仪表板
            </h1>
            <p style="opacity: 0.9; font-size: 1rem;">
              欢迎回来，系统运行正常
              <span class="inline-flex items-center gap-2 ml-3">
                <span class="w-2 h-2 rounded-full animate-pulse" style="background: #34D399;"></span>
                <span style="color: #34D399; font-weight: 500;">在线</span>
              </span>
            </p>
          </div>
          <div class="hidden md:flex items-center justify-center w-20 h-20 rounded-2xl" style="background: rgba(255,255,255,0.15);">
            <svg class="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
            </svg>
          </div>
        </div>
      </div>

      <!-- 统计卡片 -->
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <!-- 用户数 -->
        <div class="aurora-stat-card">
          <div class="aurora-stat-card-icon" style="background: rgba(99, 102, 241, 0.1);">
            <svg class="w-6 h-6" style="color: #6366F1;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
            </svg>
          </div>
          <div class="aurora-stat-card-value" style="color: #6366F1;">{@user_count}</div>
          <div class="aurora-stat-card-label mt-1">用户总数</div>
          <.link navigate={~p"/admin/users"} class="mt-3 inline-flex items-center gap-1 text-sm" style="color: #6366F1; font-weight: 500;">
            查看全部
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
            </svg>
          </.link>
        </div>

        <!-- 角色数 -->
        <div class="aurora-stat-card">
          <div class="aurora-stat-card-icon" style="background: rgba(139, 92, 246, 0.1);">
            <svg class="w-6 h-6" style="color: #8B5CF6;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
            </svg>
          </div>
          <div class="aurora-stat-card-value" style="color: #8B5CF6;">{@role_count}</div>
          <div class="aurora-stat-card-label mt-1">角色总数</div>
          <.link navigate={~p"/admin/roles"} class="mt-3 inline-flex items-center gap-1 text-sm" style="color: #8B5CF6; font-weight: 500;">
            查看全部
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
            </svg>
          </.link>
        </div>

        <!-- 权限数 -->
        <div class="aurora-stat-card">
          <div class="aurora-stat-card-icon" style="background: rgba(16, 185, 129, 0.1);">
            <svg class="w-6 h-6" style="color: #10B981;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
            </svg>
          </div>
          <div class="aurora-stat-card-value" style="color: #10B981;">{@permission_count}</div>
          <div class="aurora-stat-card-label mt-1">权限总数</div>
          <.link navigate={~p"/admin/permissions"} class="mt-3 inline-flex items-center gap-1 text-sm" style="color: #10B981; font-weight: 500;">
            查看全部
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
            </svg>
          </.link>
        </div>

        <!-- 今日操作 -->
        <div class="aurora-stat-card">
          <div class="aurora-stat-card-icon" style="background: rgba(245, 158, 11, 0.1);">
            <svg class="w-6 h-6" style="color: #F59E0B;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
            </svg>
          </div>
          <div class="aurora-stat-card-value" style="color: #F59E0B;">{@today_actions}</div>
          <div class="aurora-stat-card-label mt-1">今日操作</div>
          <span class="mt-3 text-sm" style="color: var(--color-text-muted);">系统活跃度</span>
        </div>
      </div>

      <!-- 图表区域 -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        <div class="aurora-card p-6">
          <h3 class="aurora-section-title mb-6" style="font-size: 1.125rem;">最近7天操作趋势</h3>
          <canvas id="activityChart" phx-hook="ActivityChart" data-chart={Jason.encode!(@chart_data)}></canvas>
        </div>

        <div class="aurora-card p-6">
          <h3 class="aurora-section-title mb-6" style="font-size: 1.125rem;">系统概览</h3>
          <div class="aurora-empty">
            <svg class="aurora-empty-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
            </svg>
            <p class="aurora-empty-title">更多图表即将推出</p>
            <p class="aurora-empty-desc">我们正在开发更多数据可视化功能</p>
          </div>
        </div>
      </div>

      <!-- 快速操作 -->
      <div class="aurora-card p-6">
        <h2 class="aurora-section-title mb-6" style="font-size: 1.25rem;">快速操作</h2>
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <.link navigate={~p"/admin/users"} class="aurora-action-card" style="background: linear-gradient(135deg, #6366F1 0%, #8B5CF6 100%);">
            <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
            </svg>
            <div>
              <div class="aurora-action-card-title">用户管理</div>
              <div class="aurora-action-card-desc">管理系统用户</div>
            </div>
          </.link>

          <.link navigate={~p"/admin/roles"} class="aurora-action-card" style="background: linear-gradient(135deg, #8B5CF6 0%, #A78BFA 100%);">
            <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
            </svg>
            <div>
              <div class="aurora-action-card-title">角色管理</div>
              <div class="aurora-action-card-desc">配置角色权限</div>
            </div>
          </.link>

          <.link navigate={~p"/admin/permissions"} class="aurora-action-card" style="background: linear-gradient(135deg, #10B981 0%, #34D399 100%);">
            <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
            </svg>
            <div>
              <div class="aurora-action-card-title">权限管理</div>
              <div class="aurora-action-card-desc">管理系统权限</div>
            </div>
          </.link>

          <.link navigate={~p"/users/settings"} class="aurora-action-card" style="background: linear-gradient(135deg, #F59E0B 0%, #FBBF24 100%);">
            <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
            <div>
              <div class="aurora-action-card-title">个人设置</div>
              <div class="aurora-action-card-desc">修改个人信息</div>
            </div>
          </.link>
        </div>
      </div>
    </div>
    """
  end

  defp load_stats(socket) do
    user_count = Accounts.count_users()
    role_count = Accounts.count_roles()
    permission_count = Accounts.count_permissions()
    today_actions = System.count_today_actions()
    chart_data = prepare_chart_data()

    assign(socket,
      user_count: user_count,
      role_count: role_count,
      permission_count: permission_count,
      today_actions: today_actions,
      chart_data: chart_data
    )
  end

  defp prepare_chart_data do
    stats = System.get_recent_actions_stats(7)
    dates = for i <- 6..0//-1, do: Date.utc_today() |> Date.add(-i)

    Enum.map(dates, fn date ->
      stat = Enum.find(stats, fn s -> s.date == date end)
      %{date: Date.to_string(date), count: (stat && stat.count) || 0}
    end)
  end
end
