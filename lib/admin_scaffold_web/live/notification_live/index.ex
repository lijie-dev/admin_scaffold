defmodule AdminScaffoldWeb.NotificationLive.Index do
  use AdminScaffoldWeb, :live_view

  alias AdminScaffold.System

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    if connected?(socket) do
      notifications = System.list_notifications(user.id)
      unread_count = System.unread_count(user.id)

      {:ok,
       socket
       |> assign(:page_title, "通知中心")
       |> assign(:notifications, notifications)
       |> assign(:unread_count, unread_count)
       |> assign(:selected_notifications, MapSet.new())}
    else
      {:ok,
       socket
       |> assign(:page_title, "通知中心")
       |> assign(:notifications, [])
       |> assign(:unread_count, 0)
       |> assign(:selected_notifications, MapSet.new())}
    end
  end

  @impl true
  def handle_event("mark_as_read", %{"id" => id}, socket) do
    case System.mark_as_read(String.to_integer(id)) do
      {:ok, _notification} ->
        user = socket.assigns.current_scope.user
        notifications = System.list_notifications(user.id)
        unread_count = System.unread_count(user.id)

        {:noreply,
         socket
         |> assign(:notifications, notifications)
         |> assign(:unread_count, unread_count)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "标记失败")}
    end
  end

  @impl true
  def handle_event("mark_all_as_read", _, socket) do
    user = socket.assigns.current_scope.user
    System.mark_all_as_read(user.id)

    notifications = System.list_notifications(user.id)

    {:noreply,
     socket
     |> put_flash(:info, "已标记全部为已读")
     |> assign(:notifications, notifications)
     |> assign(:unread_count, 0)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    System.delete_notification(String.to_integer(id))
    user = socket.assigns.current_scope.user
    notifications = System.list_notifications(user.id)
    unread_count = System.unread_count(user.id)

    {:noreply,
     socket
     |> put_flash(:info, "通知已删除")
     |> assign(:notifications, notifications)
     |> assign(:unread_count, unread_count)
     |> assign(:selected_notifications, MapSet.delete(socket.assigns.selected_notifications, String.to_integer(id)))}
  end

  @impl true
  def handle_event("delete_all", _, socket) do
    user = socket.assigns.current_scope.user
    System.delete_all_notifications(user.id)

    {:noreply,
     socket
     |> put_flash(:info, "已删除所有通知")
     |> assign(:notifications, [])
     |> assign(:unread_count, 0)
     |> assign(:selected_notifications, MapSet.new())}
  end

  @impl true
  def handle_event("select_notification", %{"id" => id}, socket) do
    notification_id = String.to_integer(id)
    selected = socket.assigns.selected_notifications
    new_selected = if MapSet.member?(selected, notification_id) do
      MapSet.delete(selected, notification_id)
    else
      MapSet.put(selected, notification_id)
    end
    {:noreply, assign(socket, :selected_notifications, new_selected)}
  end

  @impl true
  def handle_event("select_all", _, socket) do
    notification_ids = Enum.map(socket.assigns.notifications, & &1.id)
    {:noreply, assign(socket, :selected_notifications, MapSet.new(notification_ids))}
  end

  @impl true
  def handle_event("deselect_all", _, socket) do
    {:noreply, assign(socket, :selected_notifications, MapSet.new())}
  end

  @impl true
  def handle_event("batch_delete", _, socket) do
    selected_ids = MapSet.to_list(socket.assigns.selected_notifications)
    Enum.each(selected_ids, fn id -> System.delete_notification(id) end)

    user = socket.assigns.current_scope.user
    notifications = System.list_notifications(user.id)
    unread_count = System.unread_count(user.id)

    {:noreply,
     socket
     |> put_flash(:info, "成功删除 #{length(selected_ids)} 个通知")
     |> assign(:notifications, notifications)
     |> assign(:unread_count, unread_count)
     |> assign(:selected_notifications, MapSet.new())}
  end

  @impl true
  def handle_event("mark_selected_as_read", _, socket) do
    selected_ids = MapSet.to_list(socket.assigns.selected_notifications)
    Enum.each(selected_ids, fn id -> System.mark_as_read(id) end)

    user = socket.assigns.current_scope.user
    notifications = System.list_notifications(user.id)
    unread_count = System.unread_count(user.id)

    {:noreply,
     socket
     |> put_flash(:info, "成功标记 #{length(selected_ids)} 个通知为已读")
     |> assign(:notifications, notifications)
     |> assign(:unread_count, unread_count)
     |> assign(:selected_notifications, MapSet.new())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="aurora-container">
      <!-- 页面头部 -->
      <div class="aurora-card p-6 mb-6">
        <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <h1 class="aurora-section-title" style="font-size: 1.5rem; margin-bottom: 0.5rem;">
              通知中心
              <%= if @unread_count > 0 do %>
                <span class="aurora-badge aurora-badge-danger ml-2">
                  {@unread_count} 未读
                </span>
              <% end %>
            </h1>
            <p style="color: var(--color-text-secondary);">
              查看和管理您的通知
            </p>
          </div>
          <div class="flex items-center gap-2">
            <button phx-click="mark_all_as_read" class="aurora-btn aurora-btn-secondary">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              全部已读
            </button>
            <button phx-click="delete_all" data-confirm="确定要删除所有通知吗？" class="aurora-btn aurora-btn-ghost-danger">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
              </svg>
              删除全部
            </button>
          </div>
        </div>
      </div>

      <!-- 批量操作栏 -->
      <div :if={MapSet.size(@selected_notifications) > 0} class="aurora-card p-4 mb-6" style="background: linear-gradient(135deg, #6366F1 0%, #8B5CF6 100%); color: white;">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-3">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <span style="font-weight: 600;">已选择 {MapSet.size(@selected_notifications)} 个通知</span>
          </div>
          <div class="flex items-center gap-2">
            <button phx-click="mark_selected_as_read" class="aurora-btn" style="background: white; color: #6366F1; padding: 8px 16px; font-size: 0.875rem;">
              标记已读
            </button>
            <button phx-click="batch_delete" data-confirm="确定要删除选中的通知吗？" class="aurora-btn" style="background: rgba(239, 68, 68, 0.2); color: #FCA5A5; padding: 8px 16px; font-size: 0.875rem;">
              批量删除
            </button>
          </div>
        </div>
      </div>

      <!-- 通知列表 -->
      <div class="aurora-card">
        <div class="p-6" style="border-bottom: 1px solid var(--color-border);">
          <div class="flex items-center justify-between">
            <h2 class="aurora-section-title" style="font-size: 1.125rem;">
              通知列表
              <span class="aurora-badge aurora-badge-warning ml-2">{length(@notifications)} 条通知</span>
            </h2>
            <div class="flex items-center gap-2">
              <button phx-click="select_all" class="aurora-btn aurora-btn-secondary" style="font-size: 0.875rem;">
                全选
              </button>
              <button phx-click="deselect_all" class="aurora-btn aurora-btn-secondary" style="font-size: 0.875rem;">
                取消全选
              </button>
            </div>
          </div>
        </div>

        <div :if={length(@notifications) == 0} class="p-12 text-center" style="color: var(--color-text-muted);">
          <svg class="w-16 h-16 mx-auto mb-4 opacity-50" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
          </svg>
          <p style="font-size: 1rem;">暂无通知</p>
          <p style="font-size: 0.875rem; margin-top: 0.5rem;">有新通知时会显示在这里</p>
        </div>

        <div class="divide-y divide-gray-200">
          <div :for={notification <- @notifications} class="hover:bg-slate-50 transition-colors" style={!notification.read && "background: #EFF6FF;"}>
            <div class="p-6">
              <div class="flex items-start gap-4">
                <input
                  type="checkbox"
                  checked={MapSet.member?(@selected_notifications, notification.id)}
                  phx-click="select_notification"
                  phx-value-id={notification.id}
                  class="w-4 h-4 rounded border-2 border-gray-300 mt-1"
                />

                <div class="flex-1">
                  <div class="flex items-start justify-between mb-2">
                    <div class="flex items-center gap-2">
                      <div class={notification_icon_class(notification.type)}>
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                      </div>
                      <div>
                        <h3 class="font-semibold" style="color: var(--color-text-primary);">
                          {notification.title}
                        </h3>
                        <p style="font-size: 0.75rem; color: var(--color-text-muted);">
                          {format_time(notification.inserted_at)}
                        </p>
                      </div>
                    </div>

                    <div class="flex items-center gap-2">
                      <%= if !notification.read do %>
                        <span class="aurora-badge aurora-badge-danger" style="font-size: 0.75rem;">未读</span>
                      <% end %>
                      <button phx-click="mark_as_read" phx-value-id={notification.id} class="aurora-btn aurora-btn-secondary" style="padding: 4px 8px; font-size: 0.75rem;" disabled={notification.read}>
                        标记已读
                      </button>
                      <button phx-click="delete" phx-value-id={notification.id} class="text-red-500 hover:text-red-700">
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                        </svg>
                      </button>
                    </div>
                  </div>

                  <p style="color: var(--color-text-secondary);">
                    {notification.message}
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Helper functions

  defp notification_icon_class("info"),
    do: "w-8 h-8 rounded-full flex items-center justify-center bg-blue-100 text-blue-600"

  defp notification_icon_class("success"),
    do: "w-8 h-8 rounded-full flex items-center justify-center bg-green-100 text-green-600"

  defp notification_icon_class("warning"),
    do: "w-8 h-8 rounded-full flex items-center justify-center bg-yellow-100 text-yellow-600"

  defp notification_icon_class("danger"),
    do: "w-8 h-8 rounded-full flex items-center justify-center bg-red-100 text-red-600"

  defp notification_icon_class(_),
    do: "w-8 h-8 rounded-full flex items-center justify-center bg-gray-100 text-gray-600"

  defp format_time(datetime) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, datetime, :second)

    cond do
      diff < 60 -> "刚刚"
      diff < 3600 -> "#{div(diff, 60)} 分钟前"
      diff < 86400 -> "#{div(diff, 3600)} 小时前"
      diff < 604800 -> "#{div(diff, 86400)} 天前"
      true -> Calendar.strftime(datetime, "%Y-%m-%d %H:%M")
    end
  end
end
