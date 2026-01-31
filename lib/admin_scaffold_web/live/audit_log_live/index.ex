defmodule AdminScaffoldWeb.AuditLogLive.Index do
  use AdminScaffoldWeb, :live_view

  alias AdminScaffold.System
  alias AdminScaffoldWeb.Authorization

  @impl true
  def mount(_params, _session, socket) do
    socket = Authorization.require_permission(socket, "audit_logs.view")

    if connected?(socket) do
      {:ok, assign(socket,
        audit_logs: System.list_audit_logs(limit: 100),
        search_query: "",
        filter_user_id: nil,
        filter_resource: "all",
        filter_action: "all"
      )}
    else
      {:ok, assign(socket,
        audit_logs: [],
        search_query: "",
        filter_user_id: nil,
        filter_resource: "all",
        filter_action: "all"
      )}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "审计日志")
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign(:audit_logs, filter_audit_logs(socket.assigns |> put_in([:search_query], query)))}
  end

  @impl true
  def handle_event("filter", %{"resource" => resource, "action" => action}, socket) do
    {:noreply,
     socket
     |> assign(:filter_resource, resource)
     |> assign(:filter_action, action)
     |> assign(:audit_logs, filter_audit_logs(socket.assigns |> put_in([:filter_resource], resource) |> put_in([:filter_action], action)))}
  end

  @impl true
  def handle_event("clear_filters", _, socket) do
    {:noreply,
     socket
     |> assign(:search_query, "")
     |> assign(:filter_resource, "all")
     |> assign(:filter_action, "all")
     |> assign(:filter_user_id, nil)
     |> assign(:audit_logs, System.list_audit_logs(limit: 100))}
  end

  defp filter_audit_logs(assigns) do
    opts = [limit: 100]

    opts = if assigns.filter_resource != "all" do
      Keyword.put(opts, :resource, assigns.filter_resource)
    else
      opts
    end

    opts = if assigns.filter_action != "all" do
      Keyword.put(opts, :action, assigns.filter_action)
    else
      opts
    end

    opts = if assigns.filter_user_id do
      Keyword.put(opts, :user_id, assigns.filter_user_id)
    else
      opts
    end

    logs = System.list_audit_logs(opts)

    if assigns.search_query != "" do
      query = String.downcase(assigns.search_query)
      Enum.filter(logs, fn log ->
        String.contains?(String.downcase(log.action), query) or
        String.contains?(String.downcase(log.resource), query) or
        (log.user && String.contains?(String.downcase(log.user.email), query))
      end)
    else
      logs
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="aurora-container">
      <!-- 页面头部 -->
      <div class="aurora-card p-6 mb-6">
        <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <h1 class="aurora-section-title" style="font-size: 1.5rem; margin-bottom: 0.5rem;">审计日志</h1>
            <p style="color: var(--color-text-secondary);">
              查看系统操作记录
              <span class="aurora-badge aurora-badge-primary ml-2">ADMIN</span>
            </p>
          </div>
          <.link navigate={~p"/dashboard"} class="aurora-btn aurora-btn-secondary">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
            </svg>
            返回仪表板
          </.link>
        </div>
      </div>

      <!-- 搜索和筛选 -->
      <div class="aurora-card p-6 mb-6">
        <div class="flex flex-col md:flex-row gap-4">
          <!-- 搜索框 -->
          <div class="flex-1">
            <form phx-submit="search" phx-change="search">
              <div class="relative">
                <input
                  type="text"
                  name="query"
                  value={@search_query}
                  placeholder="搜索操作、资源或用户..."
                  class="w-full px-4 py-3 rounded-lg border-2 border-gray-200 focus:border-indigo-500 focus:outline-none"
                />
                <svg class="w-5 h-5 absolute right-3 top-3 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
              </div>
            </form>
          </div>

          <!-- 资源筛选 -->
          <div>
            <form phx-change="filter">
              <select name="resource" class="px-4 py-3 rounded-lg border-2 border-gray-200 focus:border-indigo-500 focus:outline-none">
                <option value="all" selected={@filter_resource == "all"}>所有资源</option>
                <option value="User" selected={@filter_resource == "User"}>用户</option>
                <option value="Role" selected={@filter_resource == "Role"}>角色</option>
                <option value="Permission" selected={@filter_resource == "Permission"}>权限</option>
                <option value="Menu" selected={@filter_resource == "Menu"}>菜单</option>
              </select>
            </form>
          </div>

          <!-- 操作筛选 -->
          <div>
            <form phx-change="filter">
              <select name="action" class="px-4 py-3 rounded-lg border-2 border-gray-200 focus:border-indigo-500 focus:outline-none">
                <option value="all" selected={@filter_action == "all"}>所有操作</option>
                <option value="create" selected={@filter_action == "create"}>创建</option>
                <option value="update" selected={@filter_action == "update"}>更新</option>
                <option value="delete" selected={@filter_action == "delete"}>删除</option>
                <option value="login" selected={@filter_action == "login"}>登录</option>
                <option value="logout" selected={@filter_action == "logout"}>登出</option>
              </select>
            </form>
          </div>

          <!-- 清除筛选 -->
          <div>
            <button phx-click="clear_filters" class="aurora-btn aurora-btn-secondary px-4">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
        </div>
      </div>

      <!-- 日志表格 -->
      <div class="aurora-card">
        <div class="p-6" style="border-bottom: 1px solid var(--color-border);">
          <h2 class="aurora-section-title" style="font-size: 1.125rem;">
            操作日志
            <span class="aurora-badge aurora-badge-warning ml-2">{length(@audit_logs)} 条记录</span>
          </h2>
        </div>

        <div class="overflow-x-auto">
          <table class="aurora-table">
            <thead>
              <tr>
                <th>时间</th>
                <th>用户</th>
                <th>操作</th>
                <th>资源</th>
                <th>资源ID</th>
                <th>详情</th>
                <th>IP 地址</th>
              </tr>
            </thead>

            <tbody>
              <tr :for={log <- @audit_logs} class="hover:bg-slate-50">
                <td style="font-size: 0.875rem;">
                  <div style="font-weight: 500;">{Calendar.strftime(log.inserted_at, "%Y-%m-%d")}</div>
                  <div style="font-size: 0.75rem; color: var(--color-text-muted);">{Calendar.strftime(log.inserted_at, "%H:%M:%S")}</div>
                </td>

                <td>
                  <%= if log.user do %>
                    <div class="flex items-center gap-2">
                      <div class="aurora-avatar aurora-avatar-sm">
                        {String.first(log.user.email) |> String.upcase()}
                      </div>
                      <div>
                        <div style="font-weight: 600;">{log.user.email}</div>
                        <div style="font-size: 0.75rem; color: var(--color-text-muted);">ID: #{log.user.id}</div>
                      </div>
                    </div>
                  <% else %>
                    <span style="color: var(--color-text-muted);">系统</span>
                  <% end %>
                </td>

                <td>
                  <span class={action_badge_class(log.action)}>{action_text(log.action)}</span>
                </td>

                <td style="font-weight: 600; color: var(--color-text-primary);">
                  {log.resource}
                </td>

                <td>
                  <span class="aurora-badge aurora-badge-secondary">
                    #{log.resource_id}
                  </span>
                </td>

                <td style="max-width: 200px;">
                  <span style="font-size: 0.875rem; color: var(--color-text-muted);">
                    {format_details(log.details)}
                  </span>
                </td>

                <td style="font-size: 0.875rem; color: var(--color-text-muted);">
                  {log.ip_address || "-"}
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div :if={length(@audit_logs) == 0} class="p-12 text-center" style="color: var(--color-text-muted);">
          <svg class="w-16 h-16 mx-auto mb-4 opacity-50" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
          </svg>
          <p style="font-size: 1rem;">暂无日志记录</p>
          <p style="font-size: 0.875rem; margin-top: 0.5rem;">尝试调整搜索条件</p>
        </div>
      </div>
    </div>
    """
  end

  # Helper functions

  defp action_text("create"), do: "创建"
  defp action_text("update"), do: "更新"
  defp action_text("delete"), do: "删除"
  defp action_text("login"), do: "登录"
  defp action_text("logout"), do: "登出"
  defp action_text(action), do: action

  defp action_badge_class("create"),
    do: "px-2 py-1 text-xs font-medium rounded bg-green-100 text-green-800"

  defp action_badge_class("update"),
    do: "px-2 py-1 text-xs font-medium rounded bg-blue-100 text-blue-800"

  defp action_badge_class("delete"),
    do: "px-2 py-1 text-xs font-medium rounded bg-red-100 text-red-800"

  defp action_badge_class("login"),
    do: "px-2 py-1 text-xs font-medium rounded bg-purple-100 text-purple-800"

  defp action_badge_class("logout"),
    do: "px-2 py-1 text-xs font-medium rounded bg-gray-100 text-gray-800"

  defp action_badge_class(_),
    do: "px-2 py-1 text-xs font-medium rounded bg-slate-100 text-slate-800"

  defp format_details(nil), do: "-"

  defp format_details(details) when is_map(details) do
    details
    |> Enum.map(fn {k, v} -> "#{k}: #{inspect(v)}" end)
    |> Enum.join(", ")
    |> String.slice(0, 80)
  end

  defp format_details(_), do: "-"
end
