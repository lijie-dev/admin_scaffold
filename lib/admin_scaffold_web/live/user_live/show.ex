defmodule AdminScaffoldWeb.UserLive.Show do
  use AdminScaffoldWeb, :live_view

  alias AdminScaffold.Accounts

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    user = Accounts.get_user!(id)

    {:noreply,
     socket
     |> assign(:page_title, "用户详情")
     |> assign(:user, user)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
      <div class="py-8">
        <div class="sm:flex sm:items-center">
          <div class="sm:flex-auto">
            <h1 class="text-3xl font-bold text-gray-900">用户详情</h1>
          </div>
          
          <div class="mt-4 sm:ml-16 sm:mt-0 sm:flex-none">
            <.link
              navigate={~p"/admin/users"}
              class="inline-flex items-center rounded-md bg-gray-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-gray-500"
            >
              返回列表
            </.link>
          </div>
        </div>
        
        <div class="mt-8 bg-white shadow overflow-hidden sm:rounded-lg">
          <div class="px-4 py-5 sm:px-6">
            <h3 class="text-lg leading-6 font-medium text-gray-900">用户信息</h3>
            
            <p class="mt-1 max-w-2xl text-sm text-gray-500">详细的用户账户信息</p>
          </div>
          
          <div class="border-t border-gray-200">
            <dl>
              <div class="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                <dt class="text-sm font-medium text-gray-500">用户 ID</dt>
                
                <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">{@user.id}</dd>
              </div>
              
              <div class="bg-white px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                <dt class="text-sm font-medium text-gray-500">邮箱地址</dt>
                
                <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">{@user.email}</dd>
              </div>
              
              <div class="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                <dt class="text-sm font-medium text-gray-500">邮箱确认状态</dt>
                
                <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                  <%= if @user.confirmed_at do %>
                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                      已确认
                    </span>
                  <% else %>
                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
                      未确认
                    </span>
                  <% end %>
                </dd>
              </div>
              
              <div class="bg-white px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                <dt class="text-sm font-medium text-gray-500">注册时间</dt>
                
                <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                  {Calendar.strftime(@user.inserted_at, "%Y-%m-%d %H:%M:%S")}
                </dd>
              </div>
              
              <div class="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                <dt class="text-sm font-medium text-gray-500">最后更新</dt>
                
                <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                  {Calendar.strftime(@user.updated_at, "%Y-%m-%d %H:%M:%S")}
                </dd>
              </div>
            </dl>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
