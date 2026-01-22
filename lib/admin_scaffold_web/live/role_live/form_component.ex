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

        <!-- Permissions Section -->
        <div>
          <label class="text-sm font-medium text-slate-700 mb-2 block">权限配置</label>
          <div class="border border-slate-200 rounded-lg p-4 max-h-60 overflow-y-auto">
            <div class="space-y-2">
              <div :if={Enum.empty?(@permissions)} class="text-sm text-slate-500 py-4 text-center">
                暂无可用权限
              </div>
              <div :for={permission <- @permissions} class="flex items-center gap-2 p-2 hover:bg-slate-50 rounded">
                <input
                  type="checkbox"
                  name="permissions[]"
                  value={permission.id}
                  checked={permission.id in @selected_permission_ids}
                  class="w-4 h-4 text-blue-600 border-slate-300 rounded"
                />
                <label class="text-sm text-slate-700 cursor-pointer flex-1">
                  <%= permission.name %>
                </label>
                <span class="text-xs text-slate-500">
                  <%= permission.code %>
                </span>
              </div>
            </div>
          </div>
        </div>

        <!-- Menus Section -->
        <div>
          <label class="text-sm font-medium text-slate-700 mb-2 block">菜单配置</label>
          <div class="border border-slate-200 rounded-lg p-4 max-h-60 overflow-y-auto">
            <div class="space-y-2">
              <div :if={Enum.empty?(@menus)} class="text-sm text-slate-500 py-4 text-center">
                暂无可用菜单
              </div>
              <div :for={menu <- @menus} class="flex items-center gap-2 p-2 hover:bg-slate-50 rounded">
                <input
                  type="checkbox"
                  name="menus[]"
                  value={menu.id}
                  checked={menu.id in @selected_menu_ids}
                  class="w-4 h-4 text-blue-600 border-slate-300 rounded"
                />
                <label class="text-sm text-slate-700 cursor-pointer flex-1">
                  <%= menu.name %>
                </label>
                <span class="text-xs text-slate-500">
                  <%= menu.path %>
                </span>
              </div>
            </div>
          </div>
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
    permissions = Accounts.list_permissions()
    menus = Accounts.list_menus()

    selected_permission_ids =
      if role.id do
        Accounts.get_role_permission_ids(role.id)
      else
        []
      end

    selected_menu_ids =
      if role.id do
        Accounts.get_role_menu_ids(role.id)
      else
        []
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:permissions, permissions)
     |> assign(:menus, menus)
     |> assign(:selected_permission_ids, selected_permission_ids)
     |> assign(:selected_menu_ids, selected_menu_ids)
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

  def handle_event("save", %{"role" => role_params} = params, socket) do
    permission_ids = parse_ids(params["permissions"] || [])
    menu_ids = parse_ids(params["menus"] || [])
    save_role(socket, socket.assigns.action, role_params, permission_ids, menu_ids)
  end

  defp save_role(socket, :edit, role_params, permission_ids, menu_ids) do
    case Accounts.update_role(socket.assigns.role, role_params) do
      {:ok, role} ->
        Accounts.update_role_permissions(role, permission_ids)
        Accounts.update_role_menus(role, menu_ids)
        notify_parent({:saved, role})

        {:noreply,
         socket
         |> put_flash(:info, "角色更新成功")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_role(socket, :new, role_params, permission_ids, menu_ids) do
    case Accounts.create_role(role_params) do
      {:ok, role} ->
        Accounts.update_role_permissions(role, permission_ids)
        Accounts.update_role_menus(role, menu_ids)
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

  defp parse_ids(ids) when is_list(ids) do
    ids
    |> Enum.filter(&(&1 != ""))
    |> Enum.map(&String.to_integer/1)
  end

  defp parse_ids(_), do: []
end
