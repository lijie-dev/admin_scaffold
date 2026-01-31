defmodule AdminScaffoldWeb.Plugs.ApiAuth do
  @moduledoc """
  API 认证插件。

  验证 JWT Token 并设置当前用户。
  """
  import Plug.Conn
  require Logger

  def init(opts), do: opts

  def call(conn, _opts) do
    # 获取 Authorization header
    auth_header = get_req_header(conn, "authorization")

    case verify_token(auth_header) do
      {:ok, user} ->
        assign(conn, :current_api_user, user)

      {:error, _reason} ->
        conn
        |> put_status(:unauthorized)
        |> put_resp_content_type("application/json")
        |> send_resp(401, Jason.encode!(%{error: "Unauthorized", message: "Invalid or expired token"}))
        |> halt()
    end
  end

  defp verify_token(nil), do: {:error, :no_token}

  defp verify_token(auth_header) do
    # 格式: "Bearer {token}"
    case String.split(auth_header, " ", parts: 2) do
      ["Bearer", token] ->
        verify_jwt(token)

      _ ->
        {:error, :invalid_format}
    end
  end

  defp verify_jwt(token) do
    # 使用 Joken 验证 JWT
    # 这里需要添加 Joken 依赖到 mix.exs
    # 暂时返回模拟结果
    AdminScaffold.Accounts.get_user_by_id(1)
  end
end
