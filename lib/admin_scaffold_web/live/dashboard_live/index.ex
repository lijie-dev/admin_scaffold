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
    <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
      <div class="py-8">
        <h1 class="text-3xl font-bold text-gray-900">管理仪表板</h1>
        <p class="mt-2 text-sm text-gray-700">欢迎使用后台管理系统</p>
      </div>

      <div class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
        <div class="bg-white overflow-hidden shadow rounded-lg">
          <div class="p-5">
            <div class="flex items-center">
              <div class="flex-shrink-0">
                <svg class="h-6 w-6 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
                </svg>
              </div>
              <div class="ml-5 w-0 flex-1">
                <dl>
                  <dt class="text-sm font-medium text-gray-500 truncate">
                    用户总数
                  </dt>
                  <dd class="text-3xl font-semibold text-gray-900">
                    <%= @user_count %>
                  </dd>
                </dl>
              </div>
            </div>
          </div>
          <div class="bg-gray-50 px-5 py-3">
            <div class="text-sm">
              <.link navigate={~p"/admin/users"} class="font-medium text-indigo-600 hover:text-indigo-500">
                查看全部
              </.link>
            </div>
          </div>
        </div>

        <div class="bg-white overflow-hidden shadow rounded-lg">
          <div class="p-5">
            <div class="flex items-center">
              <div class="flex-shrink-0">
                <svg class="h-6 w-6 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
              <div class="ml-5 w-0 flex-1">
                <dl>
                  <dt class="text-sm font-medium text-gray-500 truncate">
                    系统状态
                  </dt>
                  <dd class="text-lg font-semibold text-green-600">
                    运行正常
                  </dd>
                </dl>
              </div>
            </div>
          </div>
        </div>

        <div class="bg-white overflow-hidden shadow rounded-lg">
          <div class="p-5">
            <div class="flex items-center">
              <div class="flex-shrink-0">
                <svg class="h-6 w-6 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
              <div class="ml-5 w-0 flex-1">
                <dl>
                  <dt class="text-sm font-medium text-gray-500 truncate">
                    运行时间
                  </dt>
                  <dd class="text-lg font-semibold text-gray-900">
                    <%= format_uptime() %>
                  </dd>
                </dl>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="mt-8">
        <h2 class="text-xl font-semibold text-gray-900 mb-4">快速操作</h2>
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <.link
            navigate={~p"/admin/users"}
            class="relative block p-6 bg-white border border-gray-200 rounded-lg shadow hover:bg-gray-50"
          >
            <h3 class="text-lg font-semibold text-gray-900">用户管理</h3>
            <p class="mt-2 text-sm text-gray-600">管理系统用户</p>
          </.link>

          <.link
            navigate={~p"/users/settings"}
            class="relative block p-6 bg-white border border-gray-200 rounded-lg shadow hover:bg-gray-50"
          >
            <h3 class="text-lg font-semibold text-gray-900">个人设置</h3>
            <p class="mt-2 text-sm text-gray-600">修改个人信息</p>
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
