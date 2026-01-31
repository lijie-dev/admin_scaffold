defmodule AdminScaffoldWeb.ThemeController do
  use AdminScaffoldWeb, :controller

  @moduledoc """
  主题切换控制器。

  处理亮/暗模式切换。
  """

  def show(conn, _params) do
    theme = get_session(conn, "theme") || "dark"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{theme: theme}))
  end

  def update(conn, %{"theme" => theme}) do
    # 验证主题
    if theme in ["light", "dark"] do
      conn
      |> put_session(:theme, theme)
      |> put_resp_content_type("application/json")
      |> send_resp(200, Jason.encode!(%{
        success: true,
        theme: theme,
        message: "主题切换成功"
      }))
    else
      conn
      |> put_status(:unprocessable_entity)
      |> put_resp_content_type("application/json")
      |> send_resp(422, Jason.encode!(%{
        success: false,
        message: "无效的主题"
      }))
    end
  end

  def toggle(conn, _params) do
    current_theme = get_session(conn, "theme") || "dark"
    new_theme = if current_theme == "dark", do: "light", else: "dark"

    conn
    |> put_session(:theme, new_theme)
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{
      success: true,
      theme: new_theme,
      message: "主题切换成功"
    }))
  end
end
