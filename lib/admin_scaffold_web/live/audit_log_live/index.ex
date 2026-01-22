defmodule AdminScaffoldWeb.AuditLogLive.Index do
  use AdminScaffoldWeb, :live_view

  alias AdminScaffold.System
  alias AdminScaffoldWeb.Authorization

  @impl true
  def mount(_params, _session, socket) do
    socket = Authorization.require_permission(socket, "audit_logs.view")
    {:ok, stream(socket, :audit_logs, System.list_audit_logs(limit: 100))}
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
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto">
      <!-- Header -->
      <div class="bg-white p-8 mb-8 rounded-xl shadow-sm border border-slate-200">
        <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div class="flex-1">
            <h1 class="text-4xl font-bold mb-2 text-slate-900">审计日志</h1>
            <p class="text-lg text-slate-600">查看系统操作记录</p>
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

      <!-- Audit Logs Table -->
      <div class="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-slate-200">
            <thead class="bg-slate-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                  时间
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                  用户
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                  操作
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                  资源
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                  详情
                </th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-slate-200" id="audit_logs" phx-update="stream">
              <tr :for={{dom_id, log} <- @streams.audit_logs} id={dom_id} class="hover:bg-slate-50">
                <td class="px-6 py-4 whitespace-nowrap text-sm text-slate-900">
                  <%= Calendar.strftime(log.inserted_at, "%Y-%m-%d %H:%M:%S") %>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-slate-900">
                  <%= if log.user, do: log.user.email, else: "系统" %>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span class={action_badge_class(log.action)}>
                    <%= action_text(log.action) %>
                  </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-slate-900">
                  <%= log.resource %> #<%= log.resource_id %>
                </td>
                <td class="px-6 py-4 text-sm text-slate-600">
                  <%= format_details(log.details) %>
                </td>
              </tr>
            </tbody>
          </table>
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

  defp action_badge_class("create"), do: "px-2 py-1 text-xs font-medium rounded bg-green-100 text-green-800"
  defp action_badge_class("update"), do: "px-2 py-1 text-xs font-medium rounded bg-blue-100 text-blue-800"
  defp action_badge_class("delete"), do: "px-2 py-1 text-xs font-medium rounded bg-red-100 text-red-800"
  defp action_badge_class("login"), do: "px-2 py-1 text-xs font-medium rounded bg-purple-100 text-purple-800"
  defp action_badge_class("logout"), do: "px-2 py-1 text-xs font-medium rounded bg-gray-100 text-gray-800"
  defp action_badge_class(_), do: "px-2 py-1 text-xs font-medium rounded bg-slate-100 text-slate-800"

  defp format_details(nil), do: "-"
  defp format_details(details) when is_map(details) do
    details
    |> Enum.map(fn {k, v} -> "#{k}: #{inspect(v)}" end)
    |> Enum.join(", ")
    |> String.slice(0, 100)
  end
  defp format_details(_), do: "-"
end
