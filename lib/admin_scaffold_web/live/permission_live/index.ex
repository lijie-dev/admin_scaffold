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
      <!-- Header - SaaS Style -->
      <div class="bg-white p-8 mb-8 rounded-xl shadow-sm border border-slate-200">
        <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div class="flex-1">
            <h1 class="text-4xl font-bold mb-2 text-slate-900">权限管理</h1>
            
            <p class="text-lg flex items-center gap-2 text-slate-600">
              配置系统权限和访问控制
              <span class="px-3 py-1 bg-orange-100 text-orange-700 text-xs font-medium rounded">
                ACL
              </span>
            </p>
          </div>
          
          <div class="flex gap-3">
            <.link
              navigate={~p"/dashboard"}
              class="px-6 py-3 bg-slate-100 hover:bg-slate-200 text-slate-700 font-medium rounded-lg flex items-center gap-2 transition-colors"
            >
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M10 19l-7-7m0 0l7-7m-7 7h18"
                />
              </svg>
              返回仪表板
            </.link>
            <.link
              patch={~p"/admin/permissions/new"}
              class="px-6 py-3 bg-orange-600 hover:bg-orange-700 text-white font-medium rounded-lg flex items-center gap-2 transition-colors"
            >
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 4v16m8-8H4"
                />
              </svg>
              新建权限
            </.link>
          </div>
        </div>
      </div>
      <!-- Permissions Grid -->
      <div
        class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4"
        id="permissions"
        phx-update="stream"
      >
        <div
          :for={{dom_id, permission} <- @streams.permissions}
          id={dom_id}
          class="bg-white rounded-xl shadow-sm border border-slate-200 hover:shadow-lg transition-all p-6"
        >
          <!-- Permission Icon -->
          <div class="mb-4 flex justify-center">
            <div class="w-16 h-16 bg-orange-100 rounded-lg flex items-center justify-center">
              <svg
                class="w-8 h-8 text-orange-600"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
                />
              </svg>
            </div>
          </div>
          <!-- Permission Name -->
          <h3 class="text-lg font-semibold mb-2 text-center text-slate-900">{permission.name}</h3>
          <!-- Permission Slug -->
          <div class="mb-3 p-2 text-center bg-slate-50 rounded-lg">
            <p class="text-xs font-mono text-orange-600">{permission.slug}</p>
          </div>
          <!-- Permission Description -->
          <p class="text-xs mb-4 text-center min-h-[2.5rem] text-slate-600">
            {permission.description || "暂无描述"}
          </p>
          <!-- Actions -->
          <div class="flex gap-2">
            <.link
              patch={~p"/admin/permissions/#{permission.id}/edit"}
              class="flex-1 px-3 py-2 bg-blue-600 hover:bg-blue-700 text-white font-medium text-center text-xs rounded-lg transition-colors"
            >
              编辑
            </.link>
            <button
              phx-click="delete"
              phx-value-id={permission.id}
              data-confirm="确定要删除这个权限吗？"
              class="px-3 py-2 bg-pink-600 hover:bg-pink-700 text-white font-medium text-xs rounded-lg transition-colors"
            >
              删除
            </button>
          </div>
        </div>
      </div>
      <!-- Empty State -->
      <div
        :if={@streams.permissions.inserts == []}
        class="bg-white rounded-xl shadow-sm border border-slate-200 p-12 text-center"
      >
        <div class="w-24 h-24 mx-auto mb-6 bg-orange-100 rounded-xl flex items-center justify-center">
          <div class="w-full h-full flex items-center justify-center">
            <svg
              class="w-12 h-12 text-orange-600"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
              />
            </svg>
          </div>
        </div>
        
        <h3 class="text-2xl font-semibold mb-2 text-slate-900">暂无权限</h3>
        
        <p class="mb-6 text-slate-600">点击上方"新建权限"按钮创建第一个权限</p>
        
        <.link
          patch={~p"/admin/permissions/new"}
          class="px-8 py-3 bg-orange-600 hover:bg-orange-700 text-white font-medium inline-flex items-center gap-2 rounded-lg transition-colors"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
          </svg>
          创建权限
        </.link>
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
