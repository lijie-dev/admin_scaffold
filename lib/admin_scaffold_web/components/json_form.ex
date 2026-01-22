defmodule AdminScaffoldWeb.Components.JsonForm do
  @moduledoc """
  JSON 驱动的动态表单组件

  类似 owl-admin 的 amis 表单系统，通过 JSON 配置生成表单。

  ## 配置示例

      %{
        "fields" => [
          %{
            "name" => "email",
            "label" => "邮箱",
            "type" => "email",
            "required" => true
          },
          %{
            "name" => "status",
            "label" => "状态",
            "type" => "select",
            "options" => [
              {"value" => "active", "label" => "启用"},
              {"value" => "inactive", "label" => "禁用"}
            ]
          }
        ]
      }
  """

  use Phoenix.Component
  import Phoenix.HTML

  @doc """
  渲染 JSON 配置的表单
  """
  attr :form, :any, required: true, doc: "Phoenix.Form 结构"
  attr :config, :map, required: true, doc: "JSON 表单配置"
  attr :rest, :global, include: ~w(phx-target phx-change phx-submit)

  def json_form(assigns) do
    ~H"""
    <.form for={@form} {@rest}>
      <%= for field <- get_fields(@config) do %>
        <.render_field form={@form} field={field} />
      <% end %>
      <div class="flex justify-end gap-3 pt-4 border-t border-slate-200">
        <button
          type="submit"
          class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-lg transition-colors"
          phx-disable-with="提交中..."
        >
          提交
        </button>
      </div>
    </.form>
    """
  end

  @doc """
  渲染单个字段
  """
  attr :form, :any, required: true
  attr :field, :map, required: true

  def render_field(assigns) do
    ~H"""
    <div class="mb-4">
      <%= case @field["type"] do %>
        <% "text" -> %>
          <.text_input form={@form} field={@field} />
        <% "email" -> %>
          <.email_input form={@form} field={@field} />
        <% "password" -> %>
          <.password_input form={@form} field={@field} />
        <% "textarea" -> %>
          <.textarea_input form={@form} field={@field} />
        <% "select" -> %>
          <.select_input form={@form} field={@field} />
        <% "checkbox" -> %>
          <.checkbox_input form={@form} field={@field} />
        <% "number" -> %>
          <.number_input form={@form} field={@field} />
        <% "date" -> %>
          <.date_input form={@form} field={@field} />
        <% _ -> %>
          <.text_input form={@form} field={@field} />
      <% end %>
    </div>
    """
  end

  ## 字段组件

  defp text_input(assigns) do
    ~H"""
    <label class="block text-sm font-semibold text-slate-700 mb-2">
      <%= @field["label"] %>
      <%= if @field["required"], do: raw("<span class=\"text-red-500 ml-1\">*</span>") %>
    </label>
    <input
      type="text"
      name={@form[@field["name"]].name}
      value={@form[@field["name"]].value}
      class="w-full px-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
      placeholder={@field["placeholder"]}
      required={@field["required"]}
      {@field["attrs"] || %{}}
    />
    <.field_errors form={@form} field_name={@field["name"]} />
    """
  end

  defp email_input(assigns) do
    ~H"""
    <label class="block text-sm font-semibold text-slate-700 mb-2">
      <%= @field["label"] %>
      <%= if @field["required"], do: raw("<span class=\"text-red-500 ml-1\">*</span>") %>
    </label>
    <input
      type="email"
      name={@form[@field["name"]].name}
      value={@form[@field["name"]].value}
      class="w-full px-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
      placeholder={@field["placeholder"] || "user@example.com"}
      required={@field["required"]}
      {@field["attrs"] || %{}}
    />
    <.field_errors form={@form} field_name={@field["name"]} />
    """
  end

  defp password_input(assigns) do
    ~H"""
    <label class="block text-sm font-semibold text-slate-700 mb-2">
      <%= @field["label"] %>
      <%= if @field["required"], do: raw("<span class=\"text-red-500 ml-1\">*</span>") %>
    </label>
    <input
      type="password"
      name={@form[@field["name"]].name}
      value={@form[@field["name"]].value}
      class="w-full px-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
      placeholder={@field["placeholder"]}
      required={@field["required"]}
      {@field["attrs"] || %{}}
    />
    <.field_errors form={@form} field_name={@field["name"]} />
    """
  end

  defp textarea_input(assigns) do
    ~H"""
    <label class="block text-sm font-semibold text-slate-700 mb-2">
      <%= @field["label"] %>
      <%= if @field["required"], do: raw("<span class=\"text-red-500 ml-1\">*</span>") %>
    </label>
    <textarea
      name={@form[@field["name"]].name}
      class="w-full px-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
      placeholder={@field["placeholder"]}
      rows={@field["rows"] || 3}
      required={@field["required"]}
      {@field["attrs"] || %{}}
    ><%= @form[@field["name"]].value %></textarea>
    <.field_errors form={@form} field_name={@field["name"]} />
    """
  end

  defp select_input(assigns) do
    ~H"""
    <label class="block text-sm font-semibold text-slate-700 mb-2">
      <%= @field["label"] %>
      <%= if @field["required"], do: raw("<span class=\"text-red-500 ml-1\">*</span>") %>
    </label>
    <select
      name={@form[@field["name"]].name}
      class="w-full px-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
      required={@field["required"]}
      {@field["attrs"] || %{}}
    >
      <%= if @field["prompt"] do %>
        <option value="">{@field["prompt"]}</option>
      <% end %>
      <%= for option <- @field["options"] || [] do %>
        <option
          value={option["value"]}
          selected={@form[@field["name"]].value == option["value"]}
        >
          <%= option["label"] %>
        </option>
      <% end %>
    </select>
    <.field_errors form={@form} field_name={@field["name"]} />
    """
  end

  defp checkbox_input(assigns) do
    ~H"""
    <label class="flex items-center gap-2">
      <input
        type="checkbox"
        name={@form[@field["name"]].name}
        value="true"
        checked={@form[@field["name"]].value}
        class="w-5 h-5 text-blue-600 border-slate-300 rounded focus:ring-blue-500"
        {@field["attrs"] || %{}}
      />
      <span class="text-sm font-semibold text-slate-700">
        <%= @field["label"] %>
      </span>
    </label>
    <.field_errors form={@form} field_name={@field["name"]} />
    """
  end

  defp number_input(assigns) do
    ~H"""
    <label class="block text-sm font-semibold text-slate-700 mb-2">
      <%= @field["label"] %>
      <%= if @field["required"], do: raw("<span class=\"text-red-500 ml-1\">*</span>") %>
    </label>
    <input
      type="number"
      name={@form[@field["name"]].name}
      value={@form[@field["name"]].value}
      class="w-full px-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
      placeholder={@field["placeholder"]}
      required={@field["required"]}
      min={@field["min"]}
      max={@field["max"]}
      step={@field["step"]}
      {@field["attrs"] || %{}}
    />
    <.field_errors form={@form} field_name={@field["name"]} />
    """
  end

  defp date_input(assigns) do
    ~H"""
    <label class="block text-sm font-semibold text-slate-700 mb-2">
      <%= @field["label"] %>
      <%= if @field["required"], do: raw("<span class=\"text-red-500 ml-1\">*</span>") %>
    </label>
    <input
      type="date"
      name={@form[@field["name"]].name}
      value={@form[@field["name"]].value}
      class="w-full px-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
      required={@field["required"]}
      {@field["attrs"] || %{}}
    />
    <.field_errors form={@form} field_name={@field["name"]} />
    """
  end

  ## 辅助组件

  defp field_errors(assigns) do
    ~H"""
    <%= for {msg, _} <- @form[@field_name].errors do %>
      <p class="mt-1 text-sm text-red-600 flex items-center gap-1">
        <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
        </svg>
        <%= msg %>
      </p>
    <% end %>
    """
  end

  defp get_fields(config), do: config["fields"] || []
end
