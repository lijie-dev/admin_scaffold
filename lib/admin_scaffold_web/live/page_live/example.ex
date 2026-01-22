defmodule AdminScaffoldWeb.PageLive.Example do
  @moduledoc """
  示例页面 - 展示 JSON 配置驱动的页面构建
  """

  use AdminScaffoldWeb, :live_view
  import Phoenix.HTML
  alias AdminScaffold.Accounts

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket
    |> assign(:user_count, Accounts.count_users())
    |> assign(:form_config, get_form_config())
    |> assign(:table_config, get_table_config())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <!-- 页面标题 -->
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-slate-900">页面构建器示例</h1>
        <p class="mt-2 text-slate-600">
          展示如何使用 JSON 配置动态生成表单和表格
        </p>
      </div>

      <!-- 统计卡片 -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div class="bg-white p-6 rounded-xl shadow-sm border border-slate-200">
          <div class="flex items-center">
            <div class="flex-shrink-0 bg-blue-100 rounded-lg p-3">
              <svg class="h-6 w-6 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-slate-600">JSON 表单</p>
              <p class="text-2xl font-semibold text-slate-900">动态配置</p>
            </div>
          </div>
        </div>

        <div class="bg-white p-6 rounded-xl shadow-sm border border-slate-200">
          <div class="flex items-center">
            <div class="flex-shrink-0 bg-green-100 rounded-lg p-3">
              <svg class="h-6 w-6 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h18M3 14h18m-9-4v8m-7 0h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
              </svg>
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-slate-600">JSON 表格</p>
              <p class="text-2xl font-semibold text-slate-900">多种列类型</p>
            </div>
          </div>
        </div>

        <div class="bg-white p-6 rounded-xl shadow-sm border border-slate-200">
          <div class="flex items-center">
            <div class="flex-shrink-0 bg-purple-100 rounded-lg p-3">
              <svg class="h-6 w-6 text-purple-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4" />
              </svg>
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-slate-600">代码生成</p>
              <p class="text-2xl font-semibold text-slate-900">快速 CRUD</p>
            </div>
          </div>
        </div>
      </div>

      <!-- JSON 配置示例 -->
      <div class="bg-white rounded-xl shadow-sm border border-slate-200 mb-8">
        <div class="p-6 border-b border-slate-200">
          <h2 class="text-xl font-bold text-slate-900">JSON 配置示例</h2>
          <p class="mt-1 text-sm text-slate-600">
            表单和表格都通过 JSON 配置生成
          </p>
        </div>
        <div class="p-6">
          <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
            <!-- 表单配置 -->
            <div>
              <h3 class="text-sm font-semibold text-slate-700 mb-3">表单配置</h3>
              <pre class="bg-slate-800 text-slate-100 p-4 rounded-lg text-xs overflow-x-auto max-h-64"><%= Jason.encode!(@form_config, pretty: true) %></pre>
            </div>

            <!-- 表格配置 -->
            <div>
              <h3 class="text-sm font-semibold text-slate-700 mb-3">表格配置</h3>
              <pre class="bg-slate-800 text-slate-100 p-4 rounded-lg text-xs overflow-x-auto max-h-64"><%= Jason.encode!(@table_config, pretty: true) %></pre>
            </div>
          </div>
        </div>
      </div>

      <!-- 组件使用说明 -->
      <div class="bg-white rounded-xl shadow-sm border border-slate-200 mb-8">
        <div class="p-6 border-b border-slate-200">
          <h2 class="text-xl font-bold text-slate-900">组件使用说明</h2>
        </div>
        <div class="p-6 space-y-4">
          <div class="border-l-4 border-blue-500 pl-4">
            <h3 class="font-semibold text-slate-900">JsonForm 组件</h3>
            <p class="text-sm text-slate-600 mt-1">
              使用 <code class="bg-slate-100 px-1 rounded">AdminScaffoldWeb.Components.JsonForm.json_form</code> 渲染动态表单
            </p>
          </div>
          <div class="border-l-4 border-green-500 pl-4">
            <h3 class="font-semibold text-slate-900">JsonTable 组件</h3>
            <p class="text-sm text-slate-600 mt-1">
              使用 <code class="bg-slate-100 px-1 rounded">AdminScaffoldWeb.Components.JsonTable.json_table</code> 渲染动态表格
            </p>
          </div>
          <div class="border-l-4 border-purple-500 pl-4">
            <h3 class="font-semibold text-slate-900">CodeGenerator 模块</h3>
            <p class="text-sm text-slate-600 mt-1">
              使用 <code class="bg-slate-100 px-1 rounded">AdminScaffold.CodeGenerator.generate_crud/3</code> 生成 CRUD 代码
            </p>
          </div>
        </div>
      </div>

      <!-- 代码示例 -->
      <div class="bg-white rounded-xl shadow-sm border border-slate-200">
        <div class="p-6 border-b border-slate-200">
          <h2 class="text-xl font-bold text-slate-900">代码生成器使用示例</h2>
        </div>
        <div class="p-6">
          <pre class="bg-slate-800 text-slate-100 p-4 rounded-lg text-sm overflow-x-auto"><%= raw("# 在 IEx 中运行以下命令生成代码\n\n") %><%= raw("# 定义字段\n") %><%= raw("fields = [\n") %><%= raw("  %{\"name\" => \"name\", \"type\" => \"string\", \"required\" => true},\n") %><%= raw("  %{\"name\" => \"price\", \"type\" => \"decimal\", \"required\" => true},\n") %><%= raw("  %{\"name\" => \"description\", \"type\" => \"text\"}\n") %><%= raw("]\n\n") %><%= raw("# 生成代码\n") %><%= raw("AdminScaffold.CodeGenerator.generate_crud(\"products\", \"Product\", fields)\n") %></pre>
        </div>
      </div>
    </div>
    """
  end

  # 配置数据

  defp get_form_config do
    %{
      "fields" => [
        %{
          "name" => "name",
          "label" => "产品名称",
          "type" => "text",
          "placeholder" => "请输入产品名称",
          "required" => true
        },
        %{
          "name" => "email",
          "label" => "邮箱",
          "type" => "email",
          "required" => true
        },
        %{
          "name" => "category",
          "label" => "分类",
          "type" => "select",
          "options" => [
            %{"value" => "electronics", "label" => "电子产品"},
            %{"value" => "clothing", "label" => "服装"},
            %{"value" => "food", "label" => "食品"}
          ],
          "required" => true
        },
        %{
          "name" => "description",
          "label" => "描述",
          "type" => "textarea"
        }
      ]
    }
  end

  defp get_table_config do
    %{
      "title" => "产品列表",
      "columns" => [
        %{
          "name" => "id",
          "label" => "ID",
          "type" => "text"
        },
        %{
          "name" => "name",
          "label" => "产品名称",
          "type" => "text"
        },
        %{
          "name" => "status",
          "label" => "状态",
          "type" => "badge",
          "map" => %{
            "active" => %{"text" => "在售", "color" => "green"},
            "inactive" => %{"text" => "下架", "color" => "gray"},
            "draft" => %{"text" => "草稿", "color" => "yellow"}
          }
        },
        %{
          "name" => "price",
          "label" => "价格",
          "type" => "text"
        }
      ]
    }
  end
end
