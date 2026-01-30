defmodule AdminScaffoldWeb.MenuLive.FormComponent do
  use AdminScaffoldWeb, :live_component

  alias AdminScaffold.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="aurora-section-title text-xl mb-4">{@title}</h2>

      <.form
        for={@form}
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="space-y-4"
      >
        <.input field={@form[:name]} type="text" label="菜单名称" placeholder="请输入菜单名称" />
        <.input field={@form[:path]} type="text" label="菜单路径" placeholder="/dashboard" />
        <.input field={@form[:icon]} type="text" label="图标" placeholder="hero-home" />
        <.input field={@form[:sort]} type="number" label="排序" />
        <.input field={@form[:status]} type="select" label="状态" options={[{"启用", 1}, {"禁用", 0}]} />

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
  def update(%{menu: menu} = assigns, socket) do
    changeset = Accounts.change_menu(menu)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"menu" => menu_params}, socket) do
    changeset =
      socket.assigns.menu
      |> Accounts.change_menu(menu_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"menu" => menu_params}, socket) do
    save_menu(socket, socket.assigns.action, menu_params)
  end

  defp save_menu(socket, :edit, menu_params) do
    case Accounts.update_menu(socket.assigns.menu, menu_params) do
      {:ok, menu} ->
        notify_parent({:saved, menu})

        {:noreply,
         socket
         |> put_flash(:info, "菜单更新成功")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_menu(socket, :new, menu_params) do
    case Accounts.create_menu(menu_params) do
      {:ok, menu} ->
        notify_parent({:saved, menu})

        {:noreply,
         socket
         |> put_flash(:info, "菜单创建成功")
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
