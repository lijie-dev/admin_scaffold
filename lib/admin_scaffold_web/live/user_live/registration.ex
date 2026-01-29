defmodule AdminScaffoldWeb.UserLive.Registration do
  use AdminScaffoldWeb, :live_view

  alias AdminScaffold.Accounts
  alias AdminScaffold.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full max-w-md mx-auto px-6">
      <div class="aurora-card p-8" style="background: rgba(255,255,255,0.95); backdrop-filter: blur(20px);">
        <!-- 标题 -->
        <div class="text-center mb-8">
          <div class="aurora-avatar aurora-avatar-xl mx-auto mb-5" style="background: linear-gradient(135deg, #10B981 0%, #059669 100%);">
            <svg class="w-10 h-10" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" />
            </svg>
          </div>
          <h1 style="font-size: 1.75rem; font-weight: 700; color: #0F172A; margin-bottom: 0.5rem;">
            创建账户
          </h1>
          <p style="color: #64748B; font-size: 0.9375rem;">
            填写以下信息开始使用
          </p>
        </div>

        <!-- 注册表单 -->
        <.form
          for={@form}
          id="registration_form"
          action={~p"/users/register"}
          phx-submit="save"
          phx-change="validate"
        >
          <div class="aurora-form-group">
            <label class="aurora-label">邮箱地址</label>
            <input
              type="email"
              name={@form[:email].name}
              value={Phoenix.HTML.Form.normalize_value("email", @form[:email].value)}
              autocomplete="username"
              required
              phx-mounted={JS.focus()}
              class="aurora-input"
              placeholder="your@email.com"
            />
            <.error :for={msg <- Enum.map(@form[:email].errors, &translate_error/1)}>
              {msg}
            </.error>
          </div>

          <div class="aurora-form-group">
            <label class="aurora-label">密码</label>
            <input
              type="password"
              name={@form[:password].name}
              value={Phoenix.HTML.Form.normalize_value("password", @form[:password].value)}
              autocomplete="new-password"
              required
              class="aurora-input"
              placeholder="至少8个字符"
            />
            <.error :for={msg <- Enum.map(@form[:password].errors, &translate_error/1)}>
              {msg}
            </.error>
          </div>

          <button type="submit" phx-disable-with="创建中..." class="aurora-btn aurora-btn-primary w-full">
            创建账户
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 5l7 7m0 0l-7 7m7-7H3" />
            </svg>
          </button>
        </.form>

        <!-- 登录链接 -->
        <p class="text-center mt-6" style="font-size: 0.875rem; color: #64748B;">
          已有账户？
          <.link navigate={~p"/users/log-in"} style="color: #6366F1; font-weight: 600;">
            立即登录
          </.link>
        </p>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok, redirect(socket, to: AdminScaffoldWeb.UserAuth.signed_in_path(socket))}
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})
    {:ok, assign_form(socket, changeset), temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_login_instructions(
            user,
            &url(~p"/users/log-in/#{&1}")
          )

        {:noreply,
         socket
         |> put_flash(:info, "注册成功！请查收邮件确认您的账户。")
         |> push_navigate(to: ~p"/users/log-in")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end
