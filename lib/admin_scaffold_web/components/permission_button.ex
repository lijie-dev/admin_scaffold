defmodule AdminScaffoldWeb.PermissionButton do
  @moduledoc """
  基于权限的按钮组件。

  只在有权限时显示按钮。
  """
  use Phoenix.Component

  alias AdminScaffoldWeb.Authorization

  @doc """
  渲染一个按钮，只在用户有权限时显示。

  ## Examples

      <.permission_button
        socket={@socket}
        permission="users.delete"
        phx-click="delete"
        phx-value-id={@user.id}
        class="aurora-btn aurora-btn-ghost-danger"
      >
        删除
      </.permission_button>
  """
  attr :socket, :map, required: true
  attr :permission, :string, required: true
  attr :disabled, :boolean, default: false
  attr :class, :string, default: ""
  attr :rest, :global

  slot :inner_block, required: true

  def permission_button(assigns) do
    ~H"""
    <%= if Authorization.has_permission?(@socket, @permission) do %>
      <button
        class={@class}
        disabled={@disabled}
        {@rest}
      >
        <%= render_slot(@inner_block) %>
      </button>
    <% end %>
    """
  end

  @doc ~S"""
  渲染一个链接，只在用户有权限时显示。

  ## Examples

      <.permission_link
        socket={@socket}
        permission="users.edit"
        patch={~p"/admin/users/#{@user.id}/edit"}
        class="aurora-btn aurora-btn-primary"
      >
        编辑
      </.permission_link>
  """
  attr :socket, :map, required: true
  attr :permission, :string, required: true
  attr :patch, :string, default: nil
  attr :navigate, :string, default: nil
  attr :class, :string, default: ""
  attr :rest, :global

  slot :inner_block, required: true

  def permission_link(assigns) do
    ~H"""
    <%= if Authorization.has_permission?(@socket, @permission) do %>
      <%= if @patch do %>
        <.link patch={@patch} class={@class} {@rest}>
          <%= render_slot(@inner_block) %>
        </.link>
      <% else %>
        <.link navigate={@navigate} class={@class} {@rest}>
          <%= render_slot(@inner_block) %>
        </.link>
      <% end %>
    <% end %>
    """
  end

  @doc """
  渲染一个复选框，只在用户有权限时显示。

  ## Examples

      <.permission_checkbox
        socket={@socket}
        permission="users.delete"
        checked={@selected}
        phx-click="select_user"
        phx-value-id={@user.id}
      />
  """
  attr :socket, :map, required: true
  attr :permission, :string, required: true
  attr :checked, :boolean, default: false
  attr :rest, :global

  def permission_checkbox(assigns) do
    ~H"""
    <%= if Authorization.has_permission?(@socket, @permission) do %>
      <input
        type="checkbox"
        checked={@checked}
        {@rest}
        class="w-4 h-4 rounded border-2 border-gray-300"
      />
    <% end %>
    """
  end

  @doc """
  检查用户是否有权限，返回布尔值（用于条件渲染）。

  ## Examples

      <%= if has_permission?(@socket, "users.delete") do %>
        <button phx-click="delete">删除</button>
      <% end %>
  """
  def has_permission?(socket, permission_slug) do
    Authorization.has_permission?(socket, permission_slug)
  end
end
