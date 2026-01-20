defmodule AdminScaffoldWeb.PermissionLive.Index do
  use AdminScaffoldWeb, :live_view

  alias AdminScaffold.Accounts
  alias AdminScaffold.Accounts.Permission

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :permissions, Accounts.list_permissions())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "编辑权限")
    |> assign(:permission, Accounts.get_permission!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "新建权限")
    |> assign(:permission, %Permission{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "权限管理")
    |> assign(:permission, nil)
  end

  @impl true
  def handle_info({AdminScaffoldWeb.PermissionLive.FormComponent, {:saved, permission}}, socket) do
    {:noreply, stream_insert(socket, :permissions, permission)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    permission = Accounts.get_permission!(id)
    {:ok, _} = Accounts.delete_permission(permission)

    {:noreply, stream_delete(socket, :permissions, permission)}
  end
end
