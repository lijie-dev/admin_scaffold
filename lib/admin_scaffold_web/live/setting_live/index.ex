defmodule AdminScaffoldWeb.SettingLive.Index do
  use AdminScaffoldWeb, :live_view

  alias AdminScaffold.System
  alias AdminScaffoldWeb.Authorization

  @impl true
  def mount(_params, _session, socket) do
    socket = Authorization.require_permission(socket, "settings.view")

    if connected?(socket) do
      {:ok, assign(socket,
        settings: System.list_settings(),
        changeset: System.change_setting(%System.Setting{})
      )}
    else
      {:ok, assign(socket,
        settings: [],
        changeset: System.change_setting(%System.Setting{})
      )}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "系统设置")
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "新增设置")
    |> assign(:setting, %System.Setting{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    setting = System.get_setting!(id)
    socket
    |> assign(:page_title, "编辑设置")
    |> assign(:setting, setting)
  end

  @impl true
  def handle_event("save", %{"setting" => setting_params}, socket) do
    user_scope = socket.assigns.current_user_scope

    case System.create_setting(setting_params, user_scope) do
      {:ok, _setting} ->
        {:noreply,
         socket
         |> put_flash(:info, "设置保存成功")
         |> push_navigate(to: ~p"/admin/settings")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_event("update", %{"id" => id, "setting" => setting_params}, socket) do
    setting = System.get_setting!(id)
    user_scope = socket.assigns.current_user_scope

    case System.update_setting(setting, setting_params, user_scope) do
      {:ok, _setting} ->
        {:noreply,
         socket
         |> put_flash(:info, "设置更新成功")
         |> push_navigate(to: ~p"/admin/settings")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    setting = System.get_setting!(id)

    case System.delete_setting(setting) do
      {:ok, _setting} ->
        {:noreply,
         socket
         |> put_flash(:info, "设置删除成功")
         |> push_patch(to: ~p"/admin/settings")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "设置删除失败")}
    end
  end

  @impl true
  def handle_event("toggle", %{"id" => id}, socket) do
    setting = System.get_setting!(id)
    new_value = if setting.value == "true", do: "false", else: "true"

    user_scope = socket.assigns.current_user_scope

    case System.update_setting(setting, %{"value" => new_value}, user_scope) do
      {:ok, _setting} ->
        {:noreply,
         socket
         |> put_flash(:info, "设置状态已更新")
         |> push_patch(to: ~p"/admin/settings")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "设置更新失败")}
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
            <h1 class="aurora-section-title" style="font-size: 1.5rem; margin-bottom: 0.5rem;">系统设置</h1>
            <p style="color: var(--color-text-secondary);">
              管理系统全局配置
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

      <!-- 设置分类卡片 -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
        <!-- 网站信息 -->
        <div class="aurora-card p-6">
          <div class="flex items-center gap-3 mb-4">
            <div class="w-10 h-10 rounded-lg flex items-center justify-center" style="background: rgba(99, 102, 241, 0.1);">
              <svg class="w-5 h-5" style="color: #6366F1;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9" />
              </svg>
            </div>
            <h2 class="aurora-section-title" style="font-size: 1.125rem;">网站信息</h2>
          </div>

          <div class="space-y-4">
            <.form :let={f} for={@changeset} phx-submit="save" phx-change="validate">
              <div>
                <.label field={f[:key]}>系统名称</.label>
                <.input type="text" field={f[:key]} value="system.name" readonly class="bg-gray-50" />
              </div>
              <div>
                <.label field={f[:value]}>站点标题</.label>
                <.input type="text" field={f[:value]} value="管理后台" />
              </div>
              <div>
                <.label field={f[:description]}>描述</.label>
                <.input type="text" field={f[:description]} value="系统管理平台" />
              </div>
              <div>
                <.label field={f[:type]}>类型</.label>
                <.input type="text" field={f[:type]} value="string" readonly class="bg-gray-50" />
              </div>
              <.button type="submit" class="aurora-btn aurora-btn-primary w-full">
                保存设置
              </.button>
            </.form>
          </div>
        </div>

        <!-- 注册设置 -->
        <div class="aurora-card p-6">
          <div class="flex items-center gap-3 mb-4">
            <div class="w-10 h-10 rounded-lg flex items-center justify-center" style="background: rgba(139, 92, 246, 0.1);">
              <svg class="w-5 h-5" style="color: #8B5CF6;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" />
              </svg>
            </div>
            <h2 class="aurora-section-title" style="font-size: 1.125rem;">注册设置</h2>
          </div>

          <div class="space-y-4">
            <div class="flex items-center justify-between p-4 rounded-lg" style="background: var(--color-bg-muted);">
              <div>
                <div style="font-weight: 600;">允许新用户注册</div>
                <div style="font-size: 0.875rem; color: var(--color-text-muted);">关闭后将停止新用户注册</div>
              </div>
              <button phx-click="toggle" phx-value-id="1" class="aurora-toggle" style={get_toggle_style(true)}>
                <span class="aurora-toggle-thumb"></span>
              </button>
            </div>

            <div class="flex items-center justify-between p-4 rounded-lg" style="background: var(--color-bg-muted);">
              <div>
                <div style="font-weight: 600;">需要邮箱验证</div>
                <div style="font-size: 0.875rem; color: var(--color-text-muted);">用户需要验证邮箱才能登录</div>
              </div>
              <button phx-click="toggle" phx-value-id="2" class="aurora-toggle" style={get_toggle_style(true)}>
                <span class="aurora-toggle-thumb"></span>
              </button>
            </div>
          </div>
        </div>

        <!-- SMTP 设置 -->
        <div class="aurora-card p-6">
          <div class="flex items-center gap-3 mb-4">
            <div class="w-10 h-10 rounded-lg flex items-center justify-center" style="background: rgba(16, 185, 129, 0.1);">
              <svg class="w-5 h-5" style="color: #10B981;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
              </svg>
            </div>
            <h2 class="aurora-section-title" style="font-size: 1.125rem;">邮件配置</h2>
          </div>

          <div class="space-y-4">
            <.form :let={f} for={@changeset} phx-submit="save">
              <div>
                <.label field={f[:key]}>SMTP 服务器</.label>
                <.input type="text" field={f[:key]} value="smtp.host" readonly class="bg-gray-50" />
              </div>
              <div>
                <.label field={f[:value]}>服务器地址</.label>
                <.input type="text" field={f[:value]} placeholder="smtp.gmail.com" />
              </div>
              <div>
                <.label field={f[:description]}>描述</.label>
                <.input type="text" field={f[:description]} value="SMTP 服务器地址" />
              </div>
              <div>
                <.label field={f[:type]}>类型</.label>
                <.input type="text" field={f[:type]} value="string" readonly class="bg-gray-50" />
              </div>
              <.button type="submit" class="aurora-btn aurora-btn-primary w-full">
                保存设置
              </.button>
            </.form>
          </div>
        </div>

        <!-- 维护模式 -->
        <div class="aurora-card p-6">
          <div class="flex items-center gap-3 mb-4">
            <div class="w-10 h-10 rounded-lg flex items-center justify-center" style="background: rgba(245, 158, 11, 0.1);">
              <svg class="w-5 h-5" style="color: #F59E0B;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
              </svg>
            </div>
            <h2 class="aurora-section-title" style="font-size: 1.125rem;">维护模式</h2>
          </div>

          <div class="space-y-4">
            <div class="flex items-center justify-between p-4 rounded-lg" style="background: var(--color-bg-muted);">
              <div>
                <div style="font-weight: 600;">启用维护模式</div>
                <div style="font-size: 0.875rem; color: var(--color-text-muted);">网站将显示维护页面</div>
              </div>
              <button phx-click="toggle" phx-value-id="3" class="aurora-toggle" style={get_toggle_style(false)}>
                <span class="aurora-toggle-thumb"></span>
              </button>
            </div>

            <div class="flex items-center justify-between p-4 rounded-lg" style="background: var(--color-bg-muted);">
              <div>
                <div style="font-weight: 600;">只允许管理员访问</div>
                <div style="font-size: 0.875rem; color: var(--color-text-muted);">维护模式下只有管理员可访问</div>
              </div>
              <button phx-click="toggle" phx-value-id="4" class="aurora-toggle" style={get_toggle_style(true)}>
                <span class="aurora-toggle-thumb"></span>
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- 所有设置列表 -->
      <div class="aurora-card">
        <div class="p-6" style="border-bottom: 1px solid var(--color-border);">
          <h2 class="aurora-section-title" style="font-size: 1.125rem;">所有设置</h2>
        </div>

        <div class="overflow-x-auto">
          <table class="aurora-table">
            <thead>
              <tr>
                <th>设置键</th>
                <th>值</th>
                <th>描述</th>
                <th>类型</th>
                <th style="text-align: right;">操作</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={setting <- @settings}>
                <td style="font-weight: 600; color: var(--color-text-primary);">
                  <code style="background: var(--color-bg-muted); padding: 2px 6px; border-radius: 4px;">
                    {setting.key}
                  </code>
                </td>
                <td>
                  <span class="aurora-badge aurora-badge-secondary">
                    {setting.value}
                  </span>
                </td>
                <td style="color: var(--color-text-secondary);">
                  {setting.description}
                </td>
                <td>
                  <span class="aurora-badge" style="background: var(--color-bg-muted); color: var(--color-text-muted);">
                    {setting.type}
                  </span>
                </td>
                <td style="text-align: right;">
                  <button phx-click="delete" phx-value-id={setting.id} data-confirm="确定要删除此设置吗？" class="aurora-btn aurora-btn-ghost-danger" style="padding: 6px 12px; font-size: 0.875rem;">
                    删除
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
  end

  defp get_toggle_style(true) do
    "background: #6366F1;"
  end

  defp get_toggle_style(false) do
    "background: var(--color-bg-muted);"
  end
end
