defmodule AdminScaffold.System do
  @moduledoc """
  The System context.
  系统管理相关功能,包括审计日志、系统设置等。
  """

  import Ecto.Query, warn: false
  alias AdminScaffold.Repo

  alias AdminScaffold.System.{AuditLog, Setting, Notification}

  ## Setting functions

  @doc """
  返回所有设置列表。

  ## Examples

      iex> list_settings()
      [%Setting{}, ...]

  """
  def list_settings do
    Repo.all(Setting)
  end

  @doc """
  获取单个设置。

  ## Examples

      iex> get_setting!(123)
      %Setting{}

  """
  def get_setting!(id) do
    Repo.get!(Setting, id)
  end

  @doc """
  获取设置值的便捷函数。

  ## Examples

      iex> get_setting_value("system.name")
      "我的系统"

  """
  def get_setting_value(key, default \\ nil) do
    case Repo.get_by(Setting, key: key) do
      nil -> default
      setting -> setting.value
    end
  end

  @doc """
  创建新设置。

  ## Examples

      iex> create_setting(%{key: "system.name", value: "我的系统"}, user_scope)
      {:ok, %Setting{}}

  """
  def create_setting(attrs, user_scope) do
    %Setting{}
    |> Setting.changeset(attrs, user_scope)
    |> Repo.insert()
  end

  @doc """
  更新设置。

  ## Examples

      iex> update_setting(setting, %{value: "新值"}, user_scope)
      {:ok, %Setting{}}

  """
  def update_setting(%Setting{} = setting, attrs, user_scope) do
    setting
    |> Setting.changeset(attrs, user_scope)
    |> Repo.update()
  end

  @doc """
  删除设置。

  ## Examples

      iex> delete_setting(setting)
      {:ok, %Setting{}}

  """
  def delete_setting(%Setting{} = setting) do
    Repo.delete(setting)
  end

  @doc """
  返回设置 changeset。

  ## Examples

      iex> change_setting(setting)
      %Ecto.Changeset{}

  """
  def change_setting(%Setting{} = setting, attrs \\ %{}) do
    Setting.changeset(setting, attrs, %{user: %{id: nil}})
  end

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
  返回审计日志总数。
  """
  def count_audit_logs do
    Repo.aggregate(AuditLog, :count, :id)
  end

  @doc """
  返回今日操作数。
  """
  def count_today_actions do
    today = DateTime.utc_now() |> DateTime.to_date()

    from(a in AuditLog,
      where: fragment("DATE(?)", a.inserted_at) == ^today
    )
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  获取最近7天的操作统计数据。
  返回格式: [%{date: ~D[2026-01-22], count: 10}, ...]
  """
  def get_recent_actions_stats(days \\ 7) do
    start_date = Date.utc_today() |> Date.add(-days + 1)

    from(a in AuditLog,
      where: fragment("DATE(?)", a.inserted_at) >= ^start_date,
      group_by: fragment("DATE(?)", a.inserted_at),
      select: %{
        date: fragment("DATE(?)", a.inserted_at),
        count: count(a.id)
      },
      order_by: [asc: fragment("DATE(?)", a.inserted_at)]
    )
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

  ## Notification functions

  @doc """
  返回用户的通知列表。

  ## Examples

      iex> list_notifications(user_id)
      [%Notification{}, ...]

  """
  def list_notifications(user_id, opts \\ []) do
    query = from(n in Notification, where: n.user_id == ^user_id, order_by: [desc: n.inserted_at])

    query
    |> maybe_filter_read_status(opts[:read])
    |> maybe_limit(opts[:limit])
    |> preload(:user)
    |> Repo.all()
  end

  @doc """
  返回未读通知数量。
  """
  def unread_count(user_id) do
    from(n in Notification,
      where: n.user_id == ^user_id and n.read == false
    )
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  创建通知。

  ## Examples

      iex> create_notification(user, "新消息", "您有一条新消息", "info")
      {:ok, %Notification{}}

  """
  def create_notification(user, title, message, type, data \\ %{}) do
    attrs = %{
      user_id: user.id,
      title: title,
      message: message,
      type: type,
      data: data
    }

    %Notification{}
    |> Notification.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  标记通知为已读。
  """
  def mark_as_read(notification_id) do
    notification = Repo.get!(Notification, notification_id)

    notification
    |> Ecto.Changeset.change(%{read: true, read_at: DateTime.utc_now()})
    |> Repo.update()
  end

  @doc """
  标记所有通知为已读。
  """
  def mark_all_as_read(user_id) do
    from(n in Notification, where: n.user_id == ^user_id)
    |> Repo.update_all(set: [read: true, read_at: DateTime.utc_now()])
  end

  @doc """
  删除通知。
  """
  def delete_notification(notification_id) do
    notification = Repo.get!(Notification, notification_id)
    Repo.delete(notification)
  end

  @doc """
  删除所有通知。
  """
  def delete_all_notifications(user_id) do
    from(n in Notification, where: n.user_id == ^user_id)
    |> Repo.delete_all()
  end

  # Private helpers for notifications

  defp maybe_filter_read_status(query, nil), do: query
  defp maybe_filter_read_status(query, status) do
    from(n in query, where: n.read == ^status)
  end
end
