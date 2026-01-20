defmodule AdminScaffoldWeb.RoleLive.FormComponent do
  use AdminScaffoldWeb, :live_component

  alias AdminScaffold.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-4"><%= @title %></h2>

      <.form
        for={@form}
        id="role-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="space-y-4"
      >
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">角色名称</label>
          <input
            type="text"
            name="role[name]"
            value={@form[:name].value}
            class="w-full px-3 py-2 border border-gray-300 rounded-md"
            required
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">描述</label>
          <textarea
            name="role[description]"
            class="w-full px-3 py-2 border border-gray-300 rounded-md"
            rows="3"
          ><%= @form[:description].value %></textarea>
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">状态</label>
          <select
            name="role[status]"
            class="w-full px-3 py-2 border border-gray-300 rounded-md"
            required
          >
            <option value="1" selected={@form[:status].value == 1}>启用</option>
            <option value="0" selected={@form[:status].value == 0}>禁用</option>
          </select>
        </div>

        <div class="flex justify-end gap-2">
          <button
            type="submit"
            class="px-4 py-2 bg-indigo-600 text-white rounded-md hover:bg-indigo-700"
            phx-disable-with="保存中..."
          >
            保存
          </button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{role: role} = assigns, socket) do
    changeset = Accounts.change_role(role)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"role" => role_params}, socket) do
    changeset =
      socket.assigns.role
      |> Accounts.change_role(role_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"role" => role_params}, socket) do
    save_role(socket, socket.assigns.action, role_params)
  end

  defp save_role(socket, :edit, role_params) do
    case Accounts.update_role(socket.assigns.role, role_params) do
      {:ok, role} ->
        notify_parent({:saved, role})

        {:noreply,
         socket
         |> put_flash(:info, "角色更新成功")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_role(socket, :new, role_params) do
    case Accounts.create_role(role_params) do
      {:ok, role} ->
        notify_parent({:saved, role})

        {:noreply,
         socket
         |> put_flash(:info, "角色创建成功")
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
