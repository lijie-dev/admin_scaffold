defmodule AdminScaffoldWeb.RoleLive.Index do
  use AdminScaffoldWeb, :live_view

  alias AdminScaffold.Accounts
  alias AdminScaffold.Accounts.Role

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :roles, Accounts.list_roles())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "编辑角色")
    |> assign(:role, Accounts.get_role!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "新建角色")
    |> assign(:role, %Role{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "角色管理")
    |> assign(:role, nil)
  end

  @impl true
  def handle_info({AdminScaffoldWeb.RoleLive.FormComponent, {:saved, role}}, socket) do
    {:noreply, stream_insert(socket, :roles, role)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    role = Accounts.get_role!(id)
    {:ok, _} = Accounts.delete_role(role)

    {:noreply, stream_delete(socket, :roles, role)}
  end
end
