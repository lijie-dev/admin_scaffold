defmodule AdminScaffoldWeb.ChartLive do
  @moduledoc """
  图表 LiveView 组件。

  提供数据可视化功能。
  """
  use Phoenix.LiveView
  import Ecto.Query

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      {:ok, load_chart_data(socket)}
    else
      {:ok,
       assign(socket,
         user_growth_data: [],
         role_distribution: [],
         action_stats: []
       )}
    end
  end

  defp load_chart_data(socket) do
    user_growth_data = get_user_growth_data(30)
    role_distribution = get_role_distribution()
    action_stats = get_action_stats(7)

    assign(socket,
      user_growth_data: user_growth_data,
      role_distribution: role_distribution,
      action_stats: action_stats
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="aurora-container">
      <!-- 页面头部 -->
      <div class="aurora-card p-6 mb-6">
        <h1 class="aurora-section-title" style="font-size: 1.5rem; margin-bottom: 0.5rem;">数据统计</h1>
        <p style="color: var(--color-text-secondary);">
          系统数据可视化分析
        </p>
      </div>

      <!-- 图表网格 -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        <!-- 用户增长趋势 -->
        <div class="aurora-card p-6">
          <h2 class="aurora-section-title mb-6" style="font-size: 1.125rem;">用户增长趋势（30天）</h2>
          <canvas
            id="userGrowthChart"
            phx-hook="Chart"
            data-chart-type="line"
            data-chart-data={Jason.encode!(@user_growth_data)}
            data-chart-options={Jason.encode!(line_chart_options())}
            style="height: 300px;"
          ></canvas>
        </div>

        <!-- 角色分布 -->
        <div class="aurora-card p-6">
          <h2 class="aurora-section-title mb-6" style="font-size: 1.125rem;">角色分布</h2>
          <canvas
            id="roleDistributionChart"
            phx-hook="Chart"
            data-chart-type="pie"
            data-chart-data={Jason.encode!(@role_distribution)}
            data-chart-options={Jason.encode!(pie_chart_options())}
            style="height: 300px;"
          ></canvas>
        </div>
      </div>

      <!-- 操作统计 -->
      <div class="aurora-card p-6 mb-6">
        <h2 class="aurora-section-title mb-6" style="font-size: 1.125rem;">操作统计（7天）</h2>
        <canvas
          id="actionStatsChart"
          phx-hook="Chart"
          data-chart-type="bar"
          data-chart-data={Jason.encode!(@action_stats)}
          data-chart-options={Jason.encode!(bar_chart_options())}
          style="height: 300px;"
        ></canvas>
      </div>

      <!-- 统计卡片 -->
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">
        <!-- 总用户数 -->
        <div class="aurora-card p-6">
          <div class="flex items-center gap-4">
            <div class="w-12 h-12 rounded-lg flex items-center justify-center" style="background: rgba(99, 102, 241, 0.1);">
              <svg class="w-6 h-6" style="color: #6366F1;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v-1m0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
              </svg>
            </div>
            <div>
              <div style="font-size: 0.875rem; color: var(--color-text-muted);">总用户数</div>
              <div style="font-size: 1.75rem; font-weight: 700; color: #6366F1;">{get_total_users()}</div>
            </div>
          </div>
        </div>

        <!-- 活跃用户 -->
        <div class="aurora-card p-6">
          <div class="flex items-center gap-4">
            <div class="w-12 h-12 rounded-lg flex items-center justify-center" style="background: rgba(139, 92, 246, 0.1);">
              <svg class="w-6 h-6" style="color: #8B5CF6;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <div>
              <div style="font-size: 0.875rem; color: var(--color-text-muted);">活跃用户</div>
              <div style="font-size: 1.75rem; font-weight: 700; color: #8B5CF6;">{get_active_users()}</div>
            </div>
          </div>
        </div>

        <!-- 总操作数 -->
        <div class="aurora-card p-6">
          <div class="flex items-center gap-4">
            <div class="w-12 h-12 rounded-lg flex items-center justify-center" style="background: rgba(16, 185, 129, 0.1);">
              <svg class="w-6 h-6" style="color: #10B981;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7m9 10h7v-7a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
              </svg>
            </div>
            <div>
              <div style="font-size: 0.875rem; color: var(--color-text-muted);">总操作数</div>
              <div style="font-size: 1.75rem; font-weight: 700; color: #10B981;">{get_total_actions()}</div>
            </div>
          </div>
        </div>

        <!-- 今日操作 -->
        <div class="aurora-card p-6">
          <div class="flex items-center gap-4">
            <div class="w-12 h-12 rounded-lg flex items-center justify-center" style="background: rgba(245, 158, 11, 0.1);">
              <svg class="w-6 h-6" style="color: #F59E0B;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <div>
              <div style="font-size: 0.875rem; color: var(--color-text-muted);">今日操作</div>
              <div style="font-size: 1.75rem; font-weight: 700; color: #F59E0B;">{get_today_actions()}</div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Data helpers

  defp get_user_growth_data(days) do
    alias AdminScaffold.Accounts
    alias AdminScaffold.Repo
    import Ecto.Query

    start_date = Date.utc_today() |> Date.add(-days + 1)

    result = Repo.all(
      from(u in Accounts.User,
        where: fragment("DATE(?) >= ?", u.inserted_at, ^start_date),
        group_by: fragment("DATE(?)", u.inserted_at),
        select: %{
          date: fragment("DATE(?)", u.inserted_at),
          count: count(u.id)
        },
        order_by: [asc: fragment("DATE(?)", u.inserted_at)]
      )
    )

    # 填充缺失的日期
    date_range = Date.range(start_date, Date.utc_today())

    Enum.map(date_range, fn date ->
      stat = Enum.find(result, fn s -> s.date == date end)
      %{date: Date.to_string(date), count: (stat && stat.count) || 0}
    end)
  end

  defp get_role_distribution do
    alias AdminScaffold.Accounts
    alias AdminScaffold.Repo

    result = Repo.all(
      from(u in Accounts.User,
        join: ur in assoc(u, :roles),
        group_by: ur.name,
        select: %{
          name: ur.name,
          count: count(u.id)
        },
        order_by: [desc: count(u.id)]
      )
    )

    Enum.map(result, fn r ->
      %{label: r.name, value: r.count, color: get_role_color(r.name)}
    end)
  end

  defp get_action_stats(days) do
    alias AdminScaffold.System
    alias AdminScaffold.Repo

    start_date = Date.utc_today() |> Date.add(-days + 1)

    result = Repo.all(
      from(a in System.AuditLog,
        where: fragment("DATE(?) >= ?", a.inserted_at, ^start_date),
        group_by: a.action,
        select: %{
          action: a.action,
          count: count(a.id)
        },
        order_by: [desc: count(a.id)]
      )
    )

    %{
      labels: Enum.map(result, &translate_action(&1.action)),
      data: Enum.map(result, & &1.count),
      colors: Enum.map(result, &get_action_color(&1.action))
    }
  end

  defp get_total_users do
    alias AdminScaffold.Accounts
    AdminScaffold.Repo.aggregate(Accounts.User, :count, :id)
  end

  defp get_active_users do
    alias AdminScaffold.Accounts
    import Ecto.Query

    AdminScaffold.Repo.aggregate(
      from(u in Accounts.User, where: u.status == "active"),
      :count,
      :id
    )
  end

  defp get_total_actions do
    alias AdminScaffold.System
    AdminScaffold.Repo.aggregate(System.AuditLog, :count, :id)
  end

  defp get_today_actions do
    AdminScaffold.System.count_today_actions()
  end

  defp translate_action("create"), do: "创建"
  defp translate_action("update"), do: "更新"
  defp translate_action("delete"), do: "删除"
  defp translate_action("login"), do: "登录"
  defp translate_action("logout"), do: "登出"
  defp translate_action(_), do: "其他"

  defp get_action_color("create"), do: "#10B981"
  defp get_action_color("update"), do: "#6366F1"
  defp get_action_color("delete"), do: "#EF4444"
  defp get_action_color("login"), do: "#8B5CF6"
  defp get_action_color("logout"), do: "#6B7280"
  defp get_action_color(_), do: "#9CA3AF"

  defp get_role_color("admin"), do: "#6366F1"
  defp get_role_color("editor"), do: "#10B981"
  defp get_role_color("viewer"), do: "#F59E0B"
  defp get_role_color(_), do: "#8B5CF6"

  # Chart options

  defp line_chart_options do
    %{
      responsive: true,
      maintainAspectRatio: false,
      plugins: %{
        legend: %{
          display: true,
          position: "bottom"
        },
        tooltip: %{
          mode: "index",
          intersect: false
        }
      },
      scales: %{
        x: %{
          grid: %{
            display: false
          }
        },
        y: %{
          beginAtZero: true,
          grid: %{
            color: "rgba(0, 0, 0, 0.05)"
          }
        }
      },
      elements: %{
        line: %{
          tension: 0.4,
          borderWidth: 3
        },
        point: %{
          radius: 5,
          hoverRadius: 8
        }
      }
    }
  end

  defp pie_chart_options do
    %{
      responsive: true,
      maintainAspectRatio: false,
      plugins: %{
        legend: %{
          position: "right"
        },
        tooltip: %{
          callbacks: %{
            label: "function(context) { return context.label + ': ' + context.raw + ' 人'; }"
          }
        }
      }
    }
  end

  defp bar_chart_options do
    %{
      responsive: true,
      maintainAspectRatio: false,
      plugins: %{
        legend: %{
          display: false
        },
        tooltip: %{
          callbacks: %{
            label: "function(context) { return context.label + ': ' + context.raw + ' 次'; }"
          }
        }
      },
      scales: %{
        x: %{
          grid: %{
            display: false
          }
        },
        y: %{
          beginAtZero: true,
          grid: %{
            color: "rgba(0, 0, 0, 0.05)"
          }
        }
      },
      elements: %{
        bar: %{
          borderRadius: 6,
          borderWidth: 0
        }
      }
    }
  end
end
