defmodule AdminScaffoldWeb.Components.JsonTable do
  @moduledoc """
  JSON 驱动的动态表格组件

  类似 owl-admin 的 amis 表格系统，通过 JSON 配置生成表格。

  ## 配置示例

      %{
        "columns" => [
          %{
            "name" => "id",
            "label" => "ID",
            "type" => "text",
            "width" => 80
          },
          %{
            "name" => "email",
            "label" => "邮箱",
            "type" => "text"
          },
          %{
            "name" => "status",
            "label" => "状态",
            "type" => "badge",
            "map" => %{
              "active" => %{"text" => "启用", "color" => "green"},
              "inactive" => %{"text" => "禁用", "color" => "gray"}
            }
          }
        ],
        "actions" => [
          %{"label" => "编辑", "action" => "edit", "type" => "patch"},
          %{"label" => "删除", "action" => "delete", "type" => "button", "confirm" => true}
        ],
        "batch_actions" => [
          %{"label" => "批量删除", "action" => "batch_delete", "confirm" => true}
        ]
  }
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS

  attr :rows, :list, required: true, doc: "表格数据行"
  attr :config, :map, required: true, doc: "表格配置"
  attr :rest, :global

  def json_table(assigns) do
    ~H"""
    <div class="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
      <!-- Table Header -->
      <div class="p-6 border-b border-slate-200">
        <div class="flex items-center justify-between">
          <h2 class="text-xl font-bold flex items-center gap-3 text-slate-900">
            <span class="w-1 h-6 bg-blue-600 rounded"></span> {@config["title"] || "数据列表"}
          </h2>
          
          <div class="flex items-center gap-2">
            <%= if @config["searchable"] do %>
              <div class="relative">
                <input
                  type="search"
                  placeholder="搜索..."
                  class="pl-10 pr-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  phx-blur={JS.dispatch("search", detail: %{value: ""})}
                />
                <svg
                  class="w-5 h-5 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
                  />
                </svg>
              </div>
            <% end %>
          </div>
        </div>
      </div>
      <!-- Table Content -->
      <div class="overflow-x-auto">
        <table class="min-w-full">
          <thead class="bg-slate-50 border-b border-slate-200">
            <tr>
              <%= if @config["batch_actions"] do %>
                <th class="px-6 py-3 text-left">
                  <input
                    type="checkbox"
                    class="w-4 h-4 text-blue-600 border-slate-300 rounded focus:ring-blue-500"
                  />
                </th>
              <% end %>
              
              <%= for column <- get_columns(@config) do %>
                <th
                  class="text-left px-6 py-3 text-xs font-medium text-slate-600 uppercase tracking-wider"
                  style={width_style(column)}
                >
                  {column["label"]}
                </th>
              <% end %>
              
              <%= if has_actions?(@config) do %>
                <th class="text-right px-6 py-3 text-xs font-medium text-slate-600 uppercase tracking-wider">
                  操作
                </th>
              <% end %>
            </tr>
          </thead>
          
          <tbody class="bg-white divide-y divide-slate-200">
            <%= for row <- @rows do %>
              <tr class="group hover:bg-slate-50 transition-colors">
                <%= if @config["batch_actions"] do %>
                  <td class="px-6 py-4">
                    <input
                      type="checkbox"
                      class="w-4 h-4 text-blue-600 border-slate-300 rounded focus:ring-blue-500"
                    />
                  </td>
                <% end %>
                
                <%= for column <- get_columns(@config) do %>
                  <td class="px-6 py-4"><.render_cell row={row} column={column} /></td>
                <% end %>
                
                <%= if has_actions?(@config) do %>
                  <td class="px-6 py-4 text-right">
                    <.render_actions row={row} actions={get_actions(@config)} />
                  </td>
                <% end %>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
      <!-- Table Footer -->
      <div class="p-6 border-t border-slate-200 bg-slate-50 flex items-center justify-between">
        <div class="flex items-center gap-2 text-slate-500 text-sm">共 {length(@rows)} 条记录</div>
        
        <%= if @config["pagination"] do %>
          <div class="flex items-center gap-2">
            <button
              class="px-3 py-1 bg-slate-200 hover:bg-slate-300 text-slate-700 rounded text-sm disabled:opacity-50"
              disabled
            >
              上一页
            </button> <span class="text-sm text-slate-600">第 1 页</span>
            <button
              class="px-3 py-1 bg-slate-200 hover:bg-slate-300 text-slate-700 rounded text-sm disabled:opacity-50"
              disabled
            >
              下一页
            </button>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @doc """
  渲染单个单元格
  """
  attr :row, :map, required: true
  attr :column, :map, required: true

  def render_cell(assigns) do
    ~H"""
    <%= case @column["type"] do %>
      <% "text" -> %>
        <.text_cell row={@row} column={@column} />
      <% "badge" -> %>
        <.badge_cell row={@row} column={@column} />
      <% "date" -> %>
        <.date_cell row={@row} column={@column} />
      <% "link" -> %>
        <.link_cell row={@row} column={@column} />
      <% "image" -> %>
        <.image_cell row={@row} column={@column} />
      <% "custom" -> %>
        <.custom_cell row={@row} column={@column} />
      <% _ -> %>
        <.text_cell row={@row} column={@column} />
    <% end %>
    """
  end

  ## 单元格类型

  defp text_cell(assigns) do
    value = get_value(assigns.row, assigns.column["name"])
    assigns = assign(assigns, :value, value)

    ~H"""
    <span class="text-slate-900">{@value}</span>
    """
  end

  defp badge_cell(assigns) do
    raw_value = get_value(assigns.row, assigns.column["name"])

    config =
      get_in(assigns.column, ["map", raw_value]) || %{"text" => raw_value, "color" => "gray"}

    assigns = assign(assigns, :config, config)

    colors = %{
      "green" => "bg-green-100 text-green-700",
      "red" => "bg-red-100 text-red-700",
      "blue" => "bg-blue-100 text-blue-700",
      "yellow" => "bg-yellow-100 text-yellow-700",
      "gray" => "bg-gray-100 text-gray-700",
      "purple" => "bg-purple-100 text-purple-700",
      "pink" => "bg-pink-100 text-pink-700"
    }

    color_class = Map.get(colors, assigns.config["color"], colors["gray"])
    assigns = assign(assigns, :color_class, color_class)

    ~H"""
    <span class={"px-3 py-1 text-xs font-semibold rounded-full #{@color_class}"}>
      {@config["text"]}
    </span>
    """
  end

  defp date_cell(assigns) do
    value = get_value(assigns.row, assigns.column["name"])
    format = assigns.column["format"] || "%Y-%m-%d %H:%M"

    formatted =
      if value, do: Calendar.strftime(value, format), else: "-"

    assigns = assign(assigns, :formatted, formatted)

    ~H"""
    <span class="text-slate-600">{@formatted}</span>
    """
  end

  defp link_cell(assigns) do
    value = get_value(assigns.row, assigns.column["name"])
    href = assigns.column["href"] || "#"
    assigns = assigns |> assign(:value, value) |> assign(:href, href)

    ~H"""
    <a
      href={@href}
      class="text-blue-600 hover:text-blue-700 font-medium hover:underline"
    >
      {@value}
    </a>
    """
  end

  defp image_cell(assigns) do
    src = get_value(assigns.row, assigns.column["name"])
    assigns = assign(assigns, :src, src)

    ~H"""
    <img
      src={@src || "https://via.placeholder.com/40"}
      alt=""
      class="w-10 h-10 rounded-lg object-cover"
    />
    """
  end

  defp custom_cell(assigns) do
    # 支持自定义渲染函数
    render_fn = assigns.column["render"]
    value = get_value(assigns.row, assigns.column["name"])
    assigns = assigns |> assign(:render_fn, render_fn) |> assign(:value, value)

    ~H"""
    <span class="text-slate-900">{if @render_fn, do: @render_fn.(@value, @row), else: @value}</span>
    """
  end

  @doc """
  渲染操作按钮
  """
  attr :row, :map, required: true
  attr :actions, :list, required: true

  def render_actions(assigns) do
    ~H"""
    <div class="flex items-center justify-end gap-2">
      <%= for action <- @actions do %>
        <.action_button row={@row} action={action} />
      <% end %>
    </div>
    """
  end

  defp action_button(assigns) do
    assigns = assign(assigns, :primary, assigns.action["primary"] || false)

    ~H"""
    <%= case @action["type"] do %>
      <% "patch" -> %>
        <.link
          patch={build_action_path(@row, @action)}
          class={button_class(@action, @primary)}
        >
          {@action["label"]}
        </.link>
      <% "navigate" -> %>
        <.link
          navigate={build_action_path(@row, @action)}
          class={button_class(@action, @primary)}
        >
          {@action["label"]}
        </.link>
      <% "button" -> %>
        <button
          phx-click={@action["action"]}
          phx-value-id={@row["id"] || @row.id}
          data-confirm={if @action["confirm"], do: "确定要执行此操作吗？"}
          class={button_class(@action, @primary)}
        >
          {@action["label"]}
        </button>
      <% _ -> %>
        <.link
          patch={build_action_path(@row, @action)}
          class={button_class(@action, @primary)}
        >
          {@action["label"]}
        </.link>
    <% end %>
    """
  end

  ## 辅助函数

  defp get_columns(config), do: config["columns"] || []
  defp get_actions(config), do: config["actions"] || []
  defp has_actions?(config), do: length(get_actions(config)) > 0

  defp width_style(%{"width" => width}) when is_integer(width), do: "width: #{width}px"
  defp width_style(_), do: ""

  defp get_value(row, name) when is_map(row) do
    # 支持 nested 路径，如 user.email
    String.split(name, ".")
    |> Enum.reduce(row, fn
      key, acc when is_map(acc) -> Map.get(acc, key)
      _, _ -> nil
    end)
  end

  defp build_action_path(row, action) do
    base = action["path"] || "/admin/#{action["action"]}"
    id = row["id"] || row.id
    "#{base}/#{id}"
  end

  defp button_class(action, primary?) do
    base =
      "px-4 py-2 font-medium rounded-lg inline-flex items-center gap-2 text-sm transition-colors"

    color_class =
      cond do
        primary? -> "bg-blue-600 hover:bg-blue-700 text-white"
        action["color"] == "danger" -> "bg-pink-600 hover:bg-pink-700 text-white"
        action["color"] == "success" -> "bg-green-600 hover:bg-green-700 text-white"
        true -> "bg-slate-100 hover:bg-slate-200 text-slate-700"
      end

    "#{base} #{color_class}"
  end
end
