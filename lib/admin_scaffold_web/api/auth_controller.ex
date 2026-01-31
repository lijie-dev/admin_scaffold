defmodule AdminScaffoldWeb.Api.AuthController do
  use AdminScaffoldWeb, :controller

  alias AdminScaffold.Accounts

  def create(conn, %{"action" => "register"} = params) do
    case Accounts.register_user(params) do
      {:ok, user} ->
        token = generate_jwt_token(user)

        conn
        |> put_status(:created)
        |> put_resp_content_type("application/json")
        |> send_resp(201, Jason.encode!(%{
          success: true,
          message: "注册成功",
          data: %{
            user: %{
              id: user.id,
              email: user.email
            },
            token: token
          }
        }))

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_resp_content_type("application/json")
        |> send_resp(422, Jason.encode!(%{
          success: false,
          message: "注册失败",
          errors: format_errors(changeset)
        }))
    end
  end

  def create(conn, %{"action" => "login"} = params) do
    case Accounts.get_user_by_email_and_password(params["email"], params["password"]) do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> put_resp_content_type("application/json")
        |> send_resp(401, Jason.encode!(%{
          success: false,
          message: "邮箱或密码错误"
        }))

      user ->
        token = generate_jwt_token(user)

        conn
        |> put_status(:ok)
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{
          success: true,
          message: "登录成功",
          data: %{
            user: %{
              id: user.id,
              email: user.email
            },
            token: token
          }
        }))
    end
  end

  def create(conn, %{"action" => "refresh"} = params) do
    # 实现 token 刷新逻辑
    conn
    |> put_status(:ok)
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{
      success: true,
      message: "Token 刷新成功",
      data: %{
        token: params["token"]
      }
    }))
  end

  def create(conn, %{"action" => "logout"} = _params) do
    # 实现登出逻辑（使 token 失效）
    conn
    |> put_status(:ok)
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{
      success: true,
      message: "登出成功"
    }))
  end

  # 私有辅助函数

  defp generate_jwt_token(user) do
    # 使用 Joken 生成 JWT token
    # 暂时返回模拟 token
    Base.encode64("#{user.id}:#{user.email}")
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {key, {msg, _opts}}, acc ->
      Map.put(acc, key, msg)
    end, %{})
  end
end
