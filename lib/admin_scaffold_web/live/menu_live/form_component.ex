defmodule AdminScaffoldWeb.MenuLive.FormComponent do
  use AdminScaffoldWeb, :live_component

  alias AdminScaffold.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div class="brutal-card p-6" style="background: var(--color-bg-card);">
      <h2 class="text-2xl font-black mb-6" style="font-family: var(--font-display); color: var(--color-text-primary);">
        <%= @title %>
      </h2>

      <.form
        for={@form}
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="space-y-4">
          <div>
            <label class="block text-sm font-bold mb-2" style="color: var(--color-text-primary); font-family: var(--font-display);">
              菜单名称
            </label>
            <input
              type="text"
              name="menu[name]"
              value={@form[:name].value}
              class="w-full px-4 py-2 brutal-btn"
              style="background: var(--color-bg-elevated); color: var(--color-text-primary); font-family: var(--font-body);"
              placeholder="请输入菜单名称"
            />
          </div>

          <div>
            <label class="block text-sm font-bold mb-2" style="color: var(--color-text-primary); font-family: var(--font-display);">
              菜单路径
            </label>
            <input
              type="text"
              name="menu[path]"
              value={@form[:path].value}
              class="w-full px-4 py-2 brutal-btn"
              style="background: var(--color-bg-elevated); color: var(--color-text-primary); font-family: var(--font-mono);"
              placeholder="/dashboard"
            />
          </div>

          <div>
            <label class="block text-sm font-bold mb-2" style="color: var(--color-text-primary); font-family: var(--font-display);">
              图标
            </label>
            <input
              type="text"
              name="menu[icon]"
              value={@form[:icon].value}
              class="w-full px-4 py-2 brutal-btn"
              style="background: var(--color-bg-elevated); color: var(--color-text-primary); font-family: var(--font-mono);"
              placeholder="hero-home"
            />
          </div>

          <div>
            <label class="block text-sm font-bold mb-2" style="color: var(--color-text-primary); font-family: var(--font-display);">
              排序
            </label>
            <input
              type="number"
              name="menu[sort]"
              value={@form[:sort].value || 0}
              class="w-full px-4 py-2 brutal-btn"
              style="background: var(--color-bg-elevated); color: var(--color-text-primary); font-family: var(--font-mono);"
            />
          </div>

          <div>
            <label class="block text-sm font-bold mb-2" style="color: var(--color-text-primary); font-family: var(--font-display);">
              状态
            </label>
            <select
              name="menu[status]"
              class="w-full px-4 py-2 brutal-btn"
              style="background: var(--color-bg-elevated); color: var(--color-text-primary); font-family: var(--font-body);"
            >
              <option value="1" selected={@form[:status].value == 1}>启用</option>
              <option value="0" selected={@form[:status].value == 0}>禁用</option>
            </select>
          </div>
        </div>

        <div class="flex gap-3 mt-6">
          <button
            type="submit"
            phx-disable-with="保存中..."
            class="flex-1 brutal-btn px-6 py-3 text-white font-bold"
            style="background: var(--color-accent-green); font-family: var(--font-display);"
          >
            保存
          </button>
          <.link
            patch={@patch}
            class="brutal-btn px-6 py-3 text-white font-bold"
            style="background: var(--color-bg-elevated); font-family: var(--font-display);"
          >
            取消
          </.link>
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
