defmodule AdminScaffoldWeb.PermissionLive.FormComponent do
  use AdminScaffoldWeb, :live_component

  alias AdminScaffold.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="aurora-section-title text-xl mb-4">{@title}</h2>

      <.form
        for={@form}
        id="permission-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="space-y-4"
      >
        <.input field={@form[:name]} type="text" label="权限名称" required />
        <.input field={@form[:slug]} type="text" label="权限标识" required />
        <.input field={@form[:description]} type="textarea" label="描述" rows="3" />

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
  def update(%{permission: permission} = assigns, socket) do
    changeset = Accounts.change_permission(permission)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"permission" => permission_params}, socket) do
    changeset =
      socket.assigns.permission
      |> Accounts.change_permission(permission_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"permission" => permission_params}, socket) do
    save_permission(socket, socket.assigns.action, permission_params)
  end

  defp save_permission(socket, :edit, permission_params) do
    case Accounts.update_permission(socket.assigns.permission, permission_params) do
      {:ok, permission} ->
        notify_parent({:saved, permission})

        {:noreply,
         socket
         |> put_flash(:info, "权限更新成功")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_permission(socket, :new, permission_params) do
    case Accounts.create_permission(permission_params) do
      {:ok, permission} ->
        notify_parent({:saved, permission})

        {:noreply,
         socket
         |> put_flash(:info, "权限创建成功")
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
