defmodule AdminScaffoldWeb.Authorization do
  @moduledoc """
  Authorization helpers for LiveView and controllers.

  Provides functions to check permissions and restrict access to resources.
  """

  import Phoenix.LiveView

  alias AdminScaffold.Accounts

  @doc """
  Requires a specific permission for the current user in a LiveView.

  If the user doesn't have the permission, redirects to the dashboard
  with an error message.

  ## Examples

      def mount(_params, _session, socket) do
        socket = require_permission(socket, "users.manage")
        {:ok, socket}
      end
  """
  def require_permission(socket, permission_slug) do
    user = get_current_user(socket)

    if Accounts.has_permission?(user, permission_slug) do
      socket
    else
      socket
      |> put_flash(:error, "您没有权限访问此页面")
      |> redirect(to: "/dashboard")
    end
  end

  @doc """
  Checks if the current user has a specific permission.

  ## Examples

      if has_permission?(socket, "users.delete") do
        # Show delete button
      end
  """
  def has_permission?(socket, permission_slug) do
    user = get_current_user(socket)
    Accounts.has_permission?(user, permission_slug)
  end

  @doc """
  Checks if the current user can access a menu path.
  """
  def can_access_menu?(socket, menu_path) do
    user = get_current_user(socket)
    Accounts.can_access_menu?(user, menu_path)
  end

  # Private helper to get current user from socket
  defp get_current_user(socket) do
    case socket.assigns do
      %{current_scope: %{user: user}} -> user
      _ -> nil
    end
  end
end
