defmodule AdminScaffoldWeb.NotificationHelpers do
  @moduledoc """
  通知辅助函数,用于在 LiveView 中显示成功和错误消息。
  """

  import Phoenix.LiveView

  @doc """
  显示成功消息。

  ## Examples

      socket
      |> put_success("用户创建成功")

  """
  def put_success(socket, message) do
    put_flash(socket, :info, message)
  end

  @doc """
  显示错误消息。

  ## Examples

      socket
      |> put_error("操作失败,请重试")

  """
  def put_error(socket, message) do
    put_flash(socket, :error, message)
  end

  @doc """
  从 changeset 错误中提取并显示错误消息。

  ## Examples

      socket
      |> put_changeset_errors(changeset)

  """
  def put_changeset_errors(socket, changeset) do
    errors =
      changeset.errors
      |> Enum.map(fn {field, {msg, _opts}} ->
        "#{translate_field(field)}: #{msg}"
      end)
      |> Enum.join(", ")

    put_flash(socket, :error, errors)
  end

  # 翻译字段名
  defp translate_field(:email), do: "邮箱"
  defp translate_field(:password), do: "密码"
  defp translate_field(:name), do: "名称"
  defp translate_field(:slug), do: "标识符"
  defp translate_field(:description), do: "描述"
  defp translate_field(field), do: to_string(field)
end
