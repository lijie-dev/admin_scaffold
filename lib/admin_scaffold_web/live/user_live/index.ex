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

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "编辑用户")
    |> assign(:user, Accounts.get_user!(id))
  end

  @impl true
  def handle_info({AdminScaffoldWeb.UserLive.FormComponent, {:saved, _user}}, socket) do
    {:noreply, stream(socket, :users, Accounts.list_users(), reset: true)}
  end

  def handle_info({AdminScaffoldWeb.UserLive.FormComponent, :closed}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)

    case Accounts.delete_user(user) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "用户删除成功")
         |> stream_delete(:users, user)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "用户删除失败")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto">
      <!-- Header - SaaS Style -->
      <div class="bg-white p-8 mb-8 rounded-xl shadow-sm border border-slate-200">
        <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div class="flex-1">
            <h1 class="text-4xl font-bold mb-2 text-slate-900">
              用户管理
            </h1>
            <p class="text-lg flex items-center gap-2 text-slate-600">
              系统中所有注册用户的列表
              <span class="px-3 py-1 bg-blue-100 text-blue-700 text-xs font-medium rounded">
                ADMIN
              </span>
            </p>
          </div>
          <div class="flex gap-3">
            <.link
              navigate={~p"/dashboard"}
              class="px-6 py-3 bg-slate-100 hover:bg-slate-200 text-slate-700 font-medium rounded-lg flex items-center gap-2 transition-colors"
            >
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
              </svg>
              返回仪表板
            </.link>
          </div>
        </div>
      </div>

      <!-- Users Table - SaaS Style -->
      <div class="bg-white rounded-xl shadow-sm border border-slate-200">
        <div class="p-6 border-b border-slate-200">
          <div class="flex items-center justify-between">
            <h2 class="text-xl font-bold flex items-center gap-3 text-slate-900">
              <span class="w-1 h-6 bg-pink-600 rounded"></span>
              用户列表
            </h2>
            <div class="flex items-center gap-2 text-slate-500 text-sm">
              <span class="w-2 h-2 rounded-full bg-green-500 animate-pulse"></span>
              实时数据
            </div>
          </div>
        </div>

        <div class="overflow-x-auto">
          <table class="min-w-full">
            <thead class="bg-slate-50 border-b border-slate-200">
              <tr>
                <th class="text-left px-6 py-3 text-xs font-medium text-blue-600 uppercase tracking-wider">
                  ID
                </th>
                <th class="text-left px-6 py-3 text-xs font-medium text-pink-600 uppercase tracking-wider">
                  邮箱地址
                </th>
                <th class="text-left px-6 py-3 text-xs font-medium text-purple-600 uppercase tracking-wider">
                  状态
                </th>
                <th class="text-left px-6 py-3 text-xs font-medium text-purple-600 uppercase tracking-wider">
                  注册时间
                </th>
                <th class="text-right px-6 py-3 text-xs font-medium text-amber-600 uppercase tracking-wider">
                  操作
                </th>
              </tr>
            </thead>
            <tbody id="users" phx-update="stream" class="bg-white divide-y divide-slate-200">
              <tr :for={{dom_id, user} <- @streams.users} id={dom_id} class="group hover:bg-slate-50 transition-colors">
                <td class="px-6 py-4 text-blue-600">
                  <div class="font-bold">
                    #<%= user.id %>
                  </div>
                </td>
                <td class="px-6 py-4">
                  <div class="flex items-center gap-3">
                    <div class="w-10 h-10 bg-gradient-to-br from-blue-500 to-purple-600 rounded-lg flex items-center justify-center font-bold text-white">
                      <%= String.first(user.email) |> String.upcase() %>
                    </div>
                    <div>
                      <div class="font-bold text-slate-900">
                        <%= user.email %>
                      </div>
                      <div class="text-xs text-slate-500">
                        User Account
                      </div>
                    </div>
                  </div>
                </td>
                <td class="px-6 py-4">
                  <%= if user.status == "active" do %>
                    <span class="px-3 py-1 bg-green-100 text-green-700 text-xs font-semibold rounded-full">
                      启用
                    </span>
                  <% else %>
                    <span class="px-3 py-1 bg-gray-100 text-gray-700 text-xs font-semibold rounded-full">
                      禁用
                    </span>
                  <% end %>
                </td>
                <td class="px-6 py-4 text-slate-600">
                  <div class="flex flex-col">
                    <span class="font-bold">
                      <%= Calendar.strftime(user.inserted_at, "%Y-%m-%d") %>
                    </span>
                    <span class="text-xs text-slate-500">
                      <%= Calendar.strftime(user.inserted_at, "%H:%M") %>
                    </span>
                  </div>
                </td>
                <td class="px-6 py-4 text-right">
                  <div class="flex items-center justify-end gap-2">
                    <.link
                      patch={~p"/admin/users/#{user.id}/edit"}
                      class="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-lg inline-flex items-center gap-2 text-sm transition-colors"
                    >
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                      </svg>
                      编辑
                    </.link>
                    <button
                      phx-click="delete"
                      phx-value-id={user.id}
                      data-confirm="确定要删除此用户吗？"
                      class="px-4 py-2 bg-pink-600 hover:bg-pink-700 text-white font-medium rounded-lg inline-flex items-center gap-2 text-sm transition-colors"
                    >
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                      </svg>
                      删除
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Table Footer - SaaS Style -->
        <div class="p-6 border-t border-slate-200 bg-slate-50 flex items-center justify-between rounded-b-xl">
          <div class="flex items-center gap-2 text-slate-500 text-sm">
            <svg class="w-5 h-5 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            显示所有用户
          </div>
          <div class="px-4 py-2 bg-amber-100 text-amber-700 font-medium rounded-lg text-sm">
            共 <%= length(@streams.users.inserts) %> 条记录
          </div>
        </div>
      </div>

      <!-- Edit User Modal -->
      <.modal :if={@live_action == :edit} id="user-modal" show on_cancel={JS.patch(~p"/admin/users")}>
        <.live_component
          module={AdminScaffoldWeb.UserLive.FormComponent}
          id={@user.id}
          title={@page_title}
          action={@live_action}
          user={@user}
          patch={~p"/admin/users"}
        />
      </.modal>
    </div>
    """
  end
end
