defmodule AdminScaffoldWeb.ErrorHelpers do
  @moduledoc """
  统一的错误处理和用户反馈辅助函数。
  """

  use Phoenix.Component

  @doc """
  渲染错误消息的组件。
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-2 text-sm text-red-600 phx-no-feedback:hidden">
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc """
  生成表单输入的错误标签。
  """
  attr :field, Phoenix.HTML.FormField, required: true

  def error_tag(assigns) do
    ~H"""
    <.error :for={msg <- Enum.map(@field.errors, &translate_error(&1))}>
      <%= msg %>
    </.error>
    """
  end

  @doc """
  翻译错误消息为中文。
  """
  def translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
    |> translate_message()
  end

  def translate_error(msg) when is_binary(msg) do
    translate_message(msg)
  end

  # 私有函数 - 翻译常见的错误消息
  defp translate_message("can't be blank"), do: "不能为空"
  defp translate_message("has already been taken"), do: "已被使用"
  defp translate_message("is invalid"), do: "格式不正确"
  defp translate_message("must be accepted"), do: "必须接受"
  defp translate_message("has invalid format"), do: "格式不正确"
  defp translate_message("has an invalid entry"), do: "包含无效条目"
  defp translate_message("is reserved"), do: "是保留字"
  defp translate_message("does not match confirmation"), do: "两次输入不一致"
  defp translate_message("is still associated with this entry"), do: "仍然关联到此条目"

  # 长度相关
  defp translate_message("should be at least %{count} character(s)"), do: "至少需要 %{count} 个字符"
  defp translate_message("should be at most %{count} character(s)"), do: "最多 %{count} 个字符"
  defp translate_message("should be %{count} character(s)"), do: "应该是 %{count} 个字符"

  # 数值相关
  defp translate_message("must be less than %{number}"), do: "必须小于 %{number}"
  defp translate_message("must be greater than %{number}"), do: "必须大于 %{number}"
  defp translate_message("must be less than or equal to %{number}"), do: "必须小于或等于 %{number}"
  defp translate_message("must be greater than or equal to %{number}"), do: "必须大于或等于 %{number}"
  defp translate_message("must be equal to %{number}"), do: "必须等于 %{number}"

  # 默认情况
  defp translate_message(msg), do: msg
end
