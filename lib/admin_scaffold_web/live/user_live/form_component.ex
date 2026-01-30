defmodule AdminScaffoldWeb.UserLive.FormComponent do
  use AdminScaffoldWeb, :live_component

  alias AdminScaffold.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="aurora-section-title text-xl mb-6">{@title}</h2>

      <.form
        for={@form}
        id="user-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="space-y-4"
      >
        <.input
          field={@form[:email]}
          type="email"
          label="邮箱地址"
          placeholder="user@example.com"
          required
        />
        <.input
          field={@form[:status]}
          type="select"
          label="状态"
          options={[{"启用 (Active)", "active"}, {"禁用 (Inactive)", "inactive"}]}
          required
        />
        <div class="flex justify-end gap-3 pt-4" style="border-top: 1px solid var(--color-border);">
          <.link patch={@patch} class="aurora-btn aurora-btn-secondary">
            取消
          </.link>
          <button type="submit" class="aurora-btn aurora-btn-primary" phx-disable-with="保存中...">
            保存
          </button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{user: user, action: action} = assigns, socket) do
    changeset =
      case action do
        :edit -> Accounts.change_user(user)
        :new -> Accounts.change_user_registration(user)
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      case socket.assigns.action do
        :edit ->
          socket.assigns.user
          |> Accounts.change_user(user_params)
          |> Map.put(:action, :validate)

        :new ->
          socket.assigns.user
          |> Accounts.change_user_registration(user_params)
          |> Map.put(:action, :validate)
      end

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    save_user(socket, socket.assigns.action, user_params)
  end

  defp save_user(socket, :edit, user_params) do
    case Accounts.update_user(socket.assigns.user, user_params) do
      {:ok, user} ->
        notify_parent({:saved, user})

        {:noreply,
         socket
         |> put_flash(:info, "用户更新成功")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_user(socket, :new, user_params) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        notify_parent({:saved, user})

        {:noreply,
         socket
         |> put_flash(:info, "用户创建成功")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
