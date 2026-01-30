defmodule AdminScaffoldWeb.RoleLive.FormComponent do
  use AdminScaffoldWeb, :live_component

  alias AdminScaffold.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="aurora-section-title text-xl mb-4">{@title}</h2>

      <.form
        for={@form}
        id="role-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="space-y-4"
      >
        <.input field={@form[:name]} type="text" label="角色名称" required />
        <.input field={@form[:description]} type="textarea" label="描述" rows="3" />
        <.input
          field={@form[:status]}
          type="select"
          label="状态"
          options={[{"启用", 1}, {"禁用", 0}]}
          required
        />
        <!-- Permissions Section -->
        <div class="aurora-form-group">
          <label class="aurora-label">权限配置</label>
          <div class="aurora-card p-4 max-h-60 overflow-y-auto">
            <div class="space-y-2">
              <div :if={Enum.empty?(@permissions)} style="color: var(--color-text-muted);" class="text-sm py-4 text-center">
                暂无可用权限
              </div>
              <div
                :for={permission <- @permissions}
                class="flex items-center gap-2 p-2 rounded"
                style="background: var(--color-bg-secondary);"
              >
                <input
                  type="checkbox"
                  name="permissions[]"
                  value={permission.id}
                  checked={permission.id in @selected_permission_ids}
                  class="w-4 h-4 rounded"
                />
                <label style="color: var(--color-text-primary);" class="text-sm cursor-pointer flex-1">{permission.name}</label>
                <span style="color: var(--color-text-muted);" class="text-xs">{permission.slug}</span>
              </div>
            </div>
          </div>
        </div>
        <!-- Menus Section -->
        <div class="aurora-form-group">
          <label class="aurora-label">菜单配置</label>
          <div class="aurora-card p-4 max-h-60 overflow-y-auto">
            <div class="space-y-2">
              <div :if={Enum.empty?(@menus)} style="color: var(--color-text-muted);" class="text-sm py-4 text-center">
                暂无可用菜单
              </div>
              <div :for={menu <- @menus} class="flex items-center gap-2 p-2 rounded" style="background: var(--color-bg-secondary);">
                <input
                  type="checkbox"
                  name="menus[]"
                  value={menu.id}
                  checked={menu.id in @selected_menu_ids}
                  class="w-4 h-4 rounded"
                />
                <label style="color: var(--color-text-primary);" class="text-sm cursor-pointer flex-1">{menu.name}</label>
                <span style="color: var(--color-text-muted);" class="text-xs">{menu.path}</span>
              </div>
            </div>
          </div>
        </div>

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
