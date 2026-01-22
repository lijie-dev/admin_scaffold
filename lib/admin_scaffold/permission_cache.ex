defmodule AdminScaffold.PermissionCache do
  @moduledoc """
  权限缓存模块,使用 ETS 缓存用户权限数据。

  提升权限检查性能,减少数据库查询。
  """

  use GenServer
  require Logger

  @table_name :permission_cache
  @cache_ttl :timer.minutes(30)

  ## Client API

  @doc """
  启动权限缓存服务。
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  获取用户的权限列表(从缓存)。
  """
  def get_user_permissions(user_id) do
    try do
      case :ets.lookup(@table_name, {:permissions, user_id}) do
        [{_key, permissions, expires_at}] ->
          if System.system_time(:millisecond) < expires_at do
            {:ok, permissions}
          else
            :ets.delete(@table_name, {:permissions, user_id})
            {:error, :expired}
          end

        [] ->
          {:error, :not_found}
      end
    rescue
      ArgumentError ->
        {:error, :table_not_found}
    end
  end

  @doc """
  设置用户的权限列表到缓存。
  """
  def put_user_permissions(user_id, permissions) do
    try do
      expires_at = System.system_time(:millisecond) + @cache_ttl
      :ets.insert(@table_name, {{:permissions, user_id}, permissions, expires_at})
      :ok
    rescue
      ArgumentError ->
        {:error, :table_not_found}
    end
  end

  @doc """
  清除用户的权限缓存。
  """
  def clear_user_permissions(user_id) do
    try do
      :ets.delete(@table_name, {:permissions, user_id})
      :ok
    rescue
      ArgumentError ->
        {:error, :table_not_found}
    end
  end

  @doc """
  清除所有权限缓存。
  """
  def clear_all do
    try do
      :ets.delete_all_objects(@table_name)
      :ok
    rescue
      ArgumentError ->
        {:error, :table_not_found}
    end
  end

  ## Server Callbacks

  @impl true
  def init(_opts) do
    table = :ets.new(@table_name, [:named_table, :set, :public, read_concurrency: true])
    Logger.info("权限缓存服务已启动,表名: #{@table_name}")

    # 每5分钟清理一次过期缓存
    schedule_cleanup()

    {:ok, %{table: table}}
  end

  @impl true
  def handle_info(:cleanup_expired, state) do
    cleanup_expired_entries()
    schedule_cleanup()
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, _state) do
    Logger.info("权限缓存服务正在关闭")
    :ok
  end

  ## Private Functions

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup_expired, :timer.minutes(5))
  end

  defp cleanup_expired_entries do
    try do
      now = System.system_time(:millisecond)

      expired_entries =
        @table_name
        |> :ets.tab2list()
        |> Enum.filter(fn {_key, _permissions, expires_at} -> expires_at < now end)

      Enum.each(expired_entries, fn {key, _permissions, _expires_at} ->
        :ets.delete(@table_name, key)
      end)

      expired_count = length(expired_entries)

      if expired_count > 0 do
        Logger.debug("清理了 #{expired_count} 个过期的权限缓存条目")
      end
    rescue
      ArgumentError ->
        Logger.warning("清理过期缓存时 ETS 表不存在")
    end
  end
end
