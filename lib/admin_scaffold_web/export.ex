defmodule AdminScaffoldWeb.Export do
  @moduledoc """
  数据导出功能。

  支持导出为 CSV、Excel 和 PDF 格式。
  """

  require Logger
  alias AdminScaffold.Repo
  alias AdminScaffold.Accounts

  @doc """
  导出数据为 CSV。

  ## Examples

      iex> export_to_csv(User, "users")
      {:ok, "id,email,status,inserted_at\\n1,test@example.com,active,2024-01-01..."}

  """
  def export_to_csv(queryable, filename, columns \\ nil) do
    Logger.info("Exporting #{inspect(queryable)} to CSV")

    columns = columns || get_default_columns(queryable)
    data = Repo.all(queryable)

    # 构建表头
    header = Enum.join(columns, ",")

    # 构建数据行
    rows = Enum.map(data, fn row ->
      Enum.map(columns, fn col ->
        value = get_value(row, col)
        escape_csv_value(value)
      end)
      |> Enum.join(",")
    end)

    # 组合表头和数据
    csv_content = [header | rows] |> Enum.join("\n")

    {:ok, csv_content, filename: "#{filename}.csv"}
  end

  @doc """
  导出用户数据为 CSV。
  """
  def export_users_to_csv(filters \\ %{}) do
    query = from(u in Accounts.User, preload: [:roles])

    query = apply_user_filters(query, filters)

    columns = [
      "id",
      "email",
      "status",
      "roles",
      "inserted_at"
    ]

    data = Repo.all(query)

    header = Enum.join(columns, ",")

    rows = Enum.map(data, fn user ->
      [
        user.id,
        escape_csv_value(user.email),
        escape_csv_value(user.status),
        escape_csv_value(Enum.map(user.roles, & &1.name) |> Enum.join(";")),
        escape_csv_value(NaiveDateTime.to_string(user.inserted_at))
      ]
      |> Enum.join(",")
    end)

    csv_content = [header | rows] |> Enum.join("\n")

    {:ok, csv_content, filename: "users_#{Date.utc_today()}.csv"}
  end

  @doc """
  导出角色数据为 CSV。
  """
  def export_roles_to_csv(filters \\ %{}) do
    query = from(r in Accounts.Role, preload: [:permissions, :menus])

    data = Repo.all(query)

    columns = [
      "id",
      "name",
      "description",
      "permissions_count",
      "menus_count",
      "inserted_at"
    ]

    header = Enum.join(columns, ",")

    rows = Enum.map(data, fn role ->
      [
        role.id,
        escape_csv_value(role.name),
        escape_csv_value(role.description || ""),
        length(role.permissions),
        length(role.menus),
        escape_csv_value(NaiveDateTime.to_string(role.inserted_at))
      ]
      |> Enum.join(",")
    end)

    csv_content = [header | rows] |> Enum.join("\n")

    {:ok, csv_content, filename: "roles_#{Date.utc_today()}.csv"}
  end

  @doc """
  导出审计日志为 CSV。
  """
  def export_audit_logs_to_csv(filters \\ %{}) do
    alias AdminScaffold.System.AuditLog

    query = from(a in AuditLog, preload: [:user], order_by: [desc: a.inserted_at])

    query = apply_audit_log_filters(query, filters)
    query = maybe_apply_limit(query, filters[:limit])

    data = Repo.all(query)

    columns = [
      "id",
      "user_email",
      "action",
      "resource",
      "resource_id",
      "details",
      "ip_address",
      "inserted_at"
    ]

    header = Enum.join(columns, ",")

    rows = Enum.map(data, fn log ->
      [
        log.id,
        escape_csv_value(if(log.user, do: log.user.email, else: "System")),
        escape_csv_value(log.action),
        escape_csv_value(log.resource),
        escape_csv_value(log.resource_id),
        escape_csv_value(format_details(log.details)),
        escape_csv_value(log.ip_address || ""),
        escape_csv_value(NaiveDateTime.to_string(log.inserted_at))
      ]
      |> Enum.join(",")
    end)

    csv_content = [header | rows] |> Enum.join("\n")

    {:ok, csv_content, filename: "audit_logs_#{Date.utc_today()}.csv"}
  end

  # Private helper functions

  defp get_default_columns(Accounts.User), do: ["id", "email", "status", "inserted_at"]
  defp get_default_columns(Accounts.Role), do: ["id", "name", "description", "inserted_at"]
  defp get_default_columns(Accounts.Permission), do: ["id", "name", "slug", "description"]
  defp get_default_columns(Accounts.Menu), do: ["id", "name", "path", "status", "sort"]
  defp get_default_columns(_), do: ["id", "inserted_at"]

  defp get_value(record, column) do
    case Map.get(record, column) do
      nil -> ""
      value -> to_string(value)
    end
  end

  defp escape_csv_value(nil), do: ""
  defp escape_csv_value(value) when is_binary(value) do
    if String.contains?(value, [",", "\"", "\n"]) do
      "\"#{String.replace(value, "\"", "\"\"")}\""
    else
      value
    end
  end
  defp escape_csv_value(value), do: to_string(value)

  defp apply_user_filters(query, %{"status" => status}) when status != "all" do
    from(q in query, where: q.status == ^status)
  end
  defp apply_user_filters(query, %{"role_id" => role_id}) when role_id != "" do
    role_id_int = String.to_integer(role_id)
    from(q in query,
      join: u in assoc(q, :roles),
      where: u.id == ^role_id_int
    )
  end
  defp apply_user_filters(query, _filters), do: query

  defp apply_audit_log_filters(query, %{"resource" => resource}) when resource != "all" do
    from(q in query, where: q.resource == ^resource)
  end
  defp apply_audit_log_filters(query, %{"action" => action}) when action != "all" do
    from(q in query, where: q.action == ^action)
  end
  defp apply_audit_log_filters(query, _filters), do: query

  defp maybe_apply_limit(query, limit) when is_nil(limit), do: query
  defp maybe_apply_limit(query, limit), do: from(q in query, limit: ^limit)

  defp format_details(nil), do: ""
  defp format_details(details) when is_map(details) do
    details
    |> Enum.map(fn {k, v} -> "#{k}: #{inspect(v)}" end)
    |> Enum.join("; ")
    |> String.slice(0, 200)
  end
  defp format_details(_), do: ""
end
