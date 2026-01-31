defmodule AdminScaffoldWeb.ExportController do
  use AdminScaffoldWeb, :controller

  alias AdminScaffoldWeb.Export
  alias AdminScaffoldWeb.Authorization
  alias AdminScaffold.Accounts

  @doc """
  导出用户数据为 CSV。
  """
  def users_csv(conn, params) do
    # 检查权限
    user = conn.assigns.current_user
    if !Accounts.has_permission?(user, "users.view") do
      conn
      |> put_status(:forbidden)
      |> put_view(AdminScaffoldWeb.ErrorHTML)
      |> render(:error403)
    else
      case Export.export_users_to_csv(params) do
        {:ok, csv_content, filename: filename} ->
          conn
          |> put_resp_content_type("text/csv")
          |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
          |> send_resp(200, csv_content)
      end
    end
  end

  @doc """
  导出角色数据为 CSV。
  """
  def roles_csv(conn, _params) do
    user = conn.assigns.current_user
    if !Accounts.has_permission?(user, "roles.view") do
      conn
      |> put_status(:forbidden)
      |> put_view(AdminScaffoldWeb.ErrorHTML)
      |> render(:error403)
    else
      case Export.export_roles_to_csv() do
        {:ok, csv_content, filename: filename} ->
          conn
          |> put_resp_content_type("text/csv")
          |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
          |> send_resp(200, csv_content)
      end
    end
  end

  @doc """
  导出审计日志为 CSV。
  """
  def audit_logs_csv(conn, params) do
    user = conn.assigns.current_user
    if !Accounts.has_permission?(user, "audit_logs.view") do
      conn
      |> put_status(:forbidden)
      |> put_view(AdminScaffoldWeb.ErrorHTML)
      |> render(:error403)
    else
      case Export.export_audit_logs_to_csv(params) do
        {:ok, csv_content, filename: filename} ->
          conn
          |> put_resp_content_type("text/csv")
          |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
          |> send_resp(200, csv_content)
      end
    end
  end
end
