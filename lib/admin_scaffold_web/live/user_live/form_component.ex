defmodule AdminScaffoldWeb.UserLive.FormComponent do
  use AdminScaffoldWeb, :live_component

  alias AdminScaffold.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-6 text-slate-900"><%= @title %></h2>

      <.form
        for={@form}
        id="user-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="space-y-6"
      >
        <!-- Email Field -->
        <div>
          <label class="block text-sm font-semibold text-slate-700 mb-2">邮箱地址</label>
          <input
            type="email"
            name="user[email]"
            value={@form[:email].value}
            class="w-full px-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
            placeholder="user@example.com"
            required
          />
          <.error :for={msg <- @form[:email].errors}>
            <span class="text-sm text-red-600 mt-1"><%= msg %></span>
          </.error>
        </div>

        <!-- Status Field -->
        <div>
          <label class="block text-sm font-semibold text-slate-700 mb-2">状态</label>
          <select
            name="user[status]"
            class="w-full px-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
            required
          >
            <option value="active" selected={@form[:status].value == "active"}>
              启用 (Active)
            </option>
            <option value="inactive" selected={@form[:status].value == "inactive"}>
              禁用 (Inactive)
            </option>
          </select>
          <.error :for={msg <- @form[:status].errors}>
            <span class="text-sm text-red-600 mt-1"><%= msg %></span>
          </.error>
        </div>

        <!-- Form Actions -->
        <div class="flex justify-end gap-3 pt-4 border-t border-slate-200">
          <button
            type="button"
            phx-click="close"
            phx-target={@myself}
            class="px-6 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 font-medium rounded-lg transition-colors"
          >
            取消
          </button>
          <button
            type="submit"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-lg transition-colors"
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
  def update(%{user: user} = assigns, socket) do
    changeset = Accounts.change_user_registration(user)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.user
      |> Accounts.change_user_registration(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    save_user(socket, socket.assigns.action, user_params)
  end

  def handle_event("close", _params, socket) do
    notify_parent(:closed)
    {:noreply, socket}
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
