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
      <!-- Hero Header - SaaS Style -->
      <div class="mb-8 bg-gradient-to-r from-blue-600 to-indigo-600 text-white p-8 rounded-xl shadow-lg">
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-4xl font-bold mb-3">管理仪表板</h1>
            
            <p class="text-lg text-blue-100">
              欢迎回来，系统运行正常
              <span class="inline-flex items-center gap-2 ml-2">
                <span class="w-3 h-3 rounded-full bg-green-400 animate-pulse"></span>
                <span class="text-green-300 font-medium">ONLINE</span>
              </span>
            </p>
          </div>
          
          <div class="hidden md:block">
            <div class="w-24 h-24 bg-white/20 backdrop-blur-sm rounded-xl flex items-center justify-center">
              <svg class="w-16 h-16 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
                />
              </svg>
            </div>
          </div>
        </div>
      </div>
      <!-- Stats Grid -->
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
        <!-- User Count Card - SaaS Style -->
        <div class="bg-white p-6 rounded-xl shadow-sm border border-slate-200 hover:shadow-lg transition-all">
          <div class="flex items-center justify-between mb-4">
            <div class="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
              <svg class="h-6 w-6 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"
                />
              </svg>
            </div>
            
            <div class="text-right">
              <div class="text-4xl font-bold text-blue-600">{@user_count}</div>
            </div>
          </div>
          
          <div class="border-t border-slate-200 pt-4">
            <p class="text-sm font-medium text-slate-600 mb-2 uppercase tracking-wide">用户总数</p>
            
            <.link
              navigate={~p"/admin/users"}
              class="text-sm font-medium text-blue-600 hover:text-blue-700 inline-flex items-center gap-1 hover:gap-2 transition-all"
            >
              查看全部 →
            </.link>
          </div>
        </div>
        <!-- System Status Card - SaaS Style -->
        <div class="bg-white p-6 rounded-xl shadow-sm border border-slate-200 hover:shadow-lg transition-all">
          <div class="flex items-center justify-between mb-4">
            <div class="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
              <svg
                class="h-6 w-6 text-green-600"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
            </div>
            
            <div class="text-right">
              <div class="text-3xl font-bold text-green-600">100%</div>
            </div>
          </div>
          
          <div class="border-t border-slate-200 pt-4">
            <p class="text-sm font-medium text-slate-600 mb-2 uppercase tracking-wide">系统状态</p>
            
            <p class="text-base font-medium text-green-600">运行正常</p>
          </div>
        </div>
        <!-- Uptime Card - SaaS Style -->
        <div class="bg-white p-6 rounded-xl shadow-sm border border-slate-200 hover:shadow-lg transition-all">
          <div class="flex items-center justify-between mb-4">
            <div class="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center">
              <svg
                class="h-6 w-6 text-purple-600"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
            </div>
            
            <div class="text-right">
              <div class="text-2xl font-bold text-purple-600">{format_uptime()}</div>
            </div>
          </div>
          
          <div class="border-t border-slate-200 pt-4">
            <p class="text-sm font-medium text-slate-600 mb-2 uppercase tracking-wide">运行时间</p>
            
            <p class="text-sm text-slate-500">持续监控中...</p>
          </div>
        </div>
      </div>
      <!-- Quick Actions - SaaS Style -->
      <div class="bg-white p-6 rounded-xl shadow-sm border border-slate-200">
        <h2 class="text-2xl font-bold mb-6 flex items-center gap-3 text-slate-900">
          <span class="w-1 h-8 bg-blue-600 rounded"></span> 快速操作
        </h2>
        
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <.link
            navigate={~p"/admin/users"}
            class="bg-gradient-to-br from-blue-500 to-blue-600 p-6 text-white flex flex-col gap-3 rounded-lg hover:shadow-lg hover:scale-105 transition-all"
          >
            <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"
              />
            </svg>
            <div>
              <h3 class="text-lg font-bold mb-1 uppercase">用户管理</h3>
              
              <p class="text-sm opacity-90">管理系统用户</p>
            </div>
          </.link>
          <.link
            navigate={~p"/admin/roles"}
            class="bg-gradient-to-br from-purple-500 to-purple-600 p-6 text-white flex flex-col gap-3 rounded-lg hover:shadow-lg hover:scale-105 transition-all"
          >
            <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
              />
            </svg>
            <div>
              <h3 class="text-lg font-bold mb-1 uppercase">角色管理</h3>
              
              <p class="text-sm opacity-90">配置角色权限</p>
            </div>
          </.link>
          <.link
            navigate={~p"/admin/permissions"}
            class="bg-gradient-to-br from-pink-500 to-pink-600 p-6 text-white flex flex-col gap-3 rounded-lg hover:shadow-lg hover:scale-105 transition-all"
          >
            <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"
              />
            </svg>
            <div>
              <h3 class="text-lg font-bold mb-1 uppercase">权限管理</h3>
              
              <p class="text-sm opacity-90">管理系统权限</p>
            </div>
          </.link>
          <.link
            navigate={~p"/users/settings"}
            class="bg-gradient-to-br from-amber-500 to-amber-600 p-6 text-white flex flex-col gap-3 rounded-lg hover:shadow-lg hover:scale-105 transition-all"
          >
            <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"
              />
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
              />
            </svg>
            <div>
              <h3 class="text-lg font-bold mb-1 uppercase">个人设置</h3>
              
              <p class="text-sm opacity-90">修改个人信息</p>
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
