defmodule AdminScaffoldWeb.UserLive.Login do
  use AdminScaffoldWeb, :live_view

  alias AdminScaffold.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full max-w-md mx-auto px-6">
      <div class="aurora-card p-8" style="background: rgba(255,255,255,0.95); backdrop-filter: blur(20px);">
        <!-- Logo & 标题 -->
        <div class="text-center mb-8">
          <div class="aurora-avatar aurora-avatar-xl mx-auto mb-5" style="background: linear-gradient(135deg, #6366F1 0%, #8B5CF6 100%);">
            <svg class="w-10 h-10" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M5.121 17.804A13.937 13.937 0 0112 16c2.5 0 4.847.655 6.879 1.804M15 10a3 3 0 11-6 0 3 3 0 016 0zm6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <h1 style="font-size: 1.75rem; font-weight: 700; color: #0F172A; margin-bottom: 0.5rem;">
            欢迎回来
          </h1>
          <p style="color: #64748B; font-size: 0.9375rem;">
            <%= if @current_scope do %>
              请重新验证以执行敏感操作
            <% else %>
              登录您的账户以继续
            <% end %>
          </p>
        </div>

        <!-- 开发模式提示 -->
        <div :if={local_mail_adapter?()} class="aurora-toast aurora-toast-info mb-6">
          <svg class="w-5 h-5 flex-shrink-0" style="color: #3B82F6;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <div style="font-size: 0.8125rem;">
            <p style="font-weight: 600; color: #0F172A;">开发模式</p>
            <p style="color: #64748B;">
              查看邮件请访问 <.link href="/dev/mailbox" style="color: #6366F1; text-decoration: underline;">邮箱页面</.link>
            </p>
          </div>
        </div>

        <!-- 邮箱登录表单 -->
        <.form
          :let={f}
          for={@form}
          id="login_form_magic"
          action={~p"/users/log-in"}
          phx-submit="submit_magic"
        >
          <div class="aurora-form-group">
            <label class="aurora-label">邮箱地址</label>
            <input
              type="email"
              name={f[:email].name}
              value={f[:email].value}
              readonly={!!@current_scope}
              autocomplete="email"
              required
              phx-mounted={JS.focus()}
              class="aurora-input"
              placeholder="your@email.com"
            />
          </div>
          <button type="submit" class="aurora-btn aurora-btn-primary w-full">
            发送登录链接
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 5l7 7m0 0l-7 7m7-7H3" />
            </svg>
          </button>
        </.form>

        <!-- 分隔线 -->
        <div class="flex items-center gap-4 my-6">
          <div class="flex-1 h-px" style="background: #E2E8F0;"></div>
          <span style="font-size: 0.6875rem; color: #94A3B8; text-transform: uppercase; letter-spacing: 0.1em;">或使用密码</span>
          <div class="flex-1 h-px" style="background: #E2E8F0;"></div>
        </div>

        <!-- 密码登录表单 -->
        <.form
          :let={f}
          for={@form}
          id="login_form_password"
          action={~p"/users/log-in"}
          phx-submit="submit_password"
          phx-trigger-action={@trigger_submit}
        >
          <div class="aurora-form-group">
            <label class="aurora-label">邮箱地址</label>
            <input
              type="email"
              name={f[:email].name}
              value={f[:email].value}
              readonly={!!@current_scope}
              autocomplete="email"
              required
              class="aurora-input"
              placeholder="your@email.com"
            />
          </div>

          <div class="aurora-form-group">
            <label class="aurora-label">密码</label>
            <input
              type="password"
              name={@form[:password].name}
              autocomplete="current-password"
              class="aurora-input"
              placeholder="••••••••"
            />
          </div>

          <div class="space-y-3">
            <button type="submit" name={@form[:remember_me].name} value="true" class="aurora-btn aurora-btn-primary w-full">
              登录并保持在线
            </button>
            <button type="submit" class="aurora-btn aurora-btn-secondary w-full">
              仅本次登录
            </button>
          </div>
        </.form>

        <!-- 注册链接 -->
        <%= unless @current_scope do %>
          <p class="text-center mt-6" style="font-size: 0.875rem; color: #64748B;">
            还没有账户？
            <.link navigate={~p"/users/register"} style="color: #6366F1; font-weight: 600;">
              立即注册
            </.link>
          </p>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    info = "如果您的邮箱已注册，您将很快收到登录链接。"

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/users/log-in")}
  end

  defp local_mail_adapter? do
    Application.get_env(:admin_scaffold, AdminScaffold.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
