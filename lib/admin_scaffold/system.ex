defmodule AdminScaffold.System do
  @moduledoc """
  The System context.
  系统管理相关功能,包括审计日志、系统设置等。
  """

  import Ecto.Query, warn: false
  alias AdminScaffold.Repo

  alias AdminScaffold.System.AuditLog

  ## Audit Log functions

  @doc """
  创建审计日志记录。

  ## Examples

      iex> create_audit_log(%{action: "create", resource: "User"})
      {:ok, %AuditLog{}}

  """
  def create_audit_log(attrs \\ %{}) do
    %AuditLog{}
    |> AuditLog.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  记录审计日志的便捷函数。

  ## Examples

      iex> log_action(user, "create", "User", user_id, %{email: "test@example.com"})
      {:ok, %AuditLog{}}

  """
  def log_action(user, action, resource, resource_id, details \\ %{}, metadata \\ %{}) do
    attrs = %{
      user_id: user && user.id,
      action: action,
      resource: resource,
      resource_id: resource_id,
      details: details,
      ip_address: metadata[:ip_address],
      user_agent: metadata[:user_agent]
    }

    create_audit_log(attrs)
  end

  @doc """
  返回审计日志列表。

  ## Examples

      iex> list_audit_logs()
      [%AuditLog{}, ...]

  """
  def list_audit_logs(opts \\ []) do
    query = from(a in AuditLog, order_by: [desc: a.inserted_at])

    query
    |> maybe_filter_by_user(opts[:user_id])
    |> maybe_filter_by_resource(opts[:resource])
    |> maybe_filter_by_action(opts[:action])
    |> maybe_limit(opts[:limit])
    |> preload(:user)
    |> Repo.all()
  end

  @doc """
  获取单个审计日志。

  ## Examples

      iex> get_audit_log!(123)
      %AuditLog{}

  """
  def get_audit_log!(id) do
    AuditLog
    |> preload(:user)
    |> Repo.get!(id)
  end

  # Private helper functions

  defp maybe_filter_by_user(query, nil), do: query
  defp maybe_filter_by_user(query, user_id) do
    from(a in query, where: a.user_id == ^user_id)
  end

  defp maybe_filter_by_resource(query, nil), do: query
  defp maybe_filter_by_resource(query, resource) do
    from(a in query, where: a.resource == ^resource)
  end

  defp maybe_filter_by_action(query, nil), do: query
  defp maybe_filter_by_action(query, action) do
    from(a in query, where: a.action == ^action)
  end

  defp maybe_limit(query, nil), do: query
  defp maybe_limit(query, limit) do
    from(a in query, limit: ^limit)
  end
end
