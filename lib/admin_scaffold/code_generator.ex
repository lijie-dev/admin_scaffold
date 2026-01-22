defmodule AdminScaffold.CodeGenerator do
  @moduledoc """
  代码生成器模块

  类似 owl-admin 的代码生成器，根据数据库表结构自动生成 CRUD 代码。
  支持生成 Context、Schema、LiveView、测试等。
  """

  @doc """
  生成完整的 CRUD 代码

  ## 参数
    - table_name: 表名
    - module_name: 模块名 (如 "Product")
    - schema_fields: 字段定义列表

  ## 返回
    {:ok, %{context: ..., schema: ..., live_view: ..., test: ...}}
  """
  def generate_crud(table_name, module_name, schema_fields) do
    context_module = "AdminScaffold.#{module_name}s"
    schema_module = "AdminScaffold.#{module_name}s.#{module_name}"
    live_view_module = "AdminScaffoldWeb.#{module_name}Live.Index"

    %{
      context: generate_context(context_module, table_name, module_name, schema_fields),
      schema: generate_schema(schema_module, table_name, schema_fields),
      migration: generate_migration(table_name, schema_fields),
      live_view: generate_live_view(live_view_module, module_name, schema_fields),
      test: generate_test(context_module, module_name)
    }
  end

  @doc """
  生成 Context 代码
  """
  def generate_context(context_module, _table_name, module_name, _schema_fields) do
    singular = String.downcase(module_name)
    plural = "#{singular}s"

    """
    defmodule #{context_module} do
      @moduledoc \"\"\"
      The #{module_name} Context.
      \"\"\"

      import Ecto.Query, warn: false
      alias AdminScaffold.Repo
      alias #{context_module}.#{module_name}

      @doc \"\"\"
      Returns the list of #{plural}.
      \"\"\"
      def list_#{plural}(opts \\\\ []) do
        #{module_name}
        |> order_by(asc: :id)
        |> Repo.all()
      end

      @doc \"\"\"
      Gets a single #{singular}.
      \"\"\"
      def get_#{singular}!(id), do: Repo.get!(#{module_name}, id)

      @doc \"\"\"
      Creates a #{singular}.
      \"\"\"
      def create_#{singular}(attrs \\\\ %{}) do
        %#{module_name}{}
        |> #{module_name}.changeset(attrs)
        |> Repo.insert()
      end

      @doc \"\"\"
      Updates a #{singular}.
      \"\"\"
      def update_#{singular}(%#{module_name}{} = #{singular}, attrs) do
        #{singular}
        |> #{module_name}.changeset(attrs)
        |> Repo.update()
      end

      @doc \"\"\"
      Deletes a #{singular}.
      \"\"\"
      def delete_#{singular}(%#{module_name}{} = #{singular}) do
        Repo.delete(#{singular})
      end

      @doc \"\"\"
      Returns an `%Ecto.Changeset{}` for tracking #{singular} changes.
      \"\"\"
      def change_#{singular}(%#{module_name}{} = #{singular}, attrs \\\\ %{}) do
        #{module_name}.changeset(#{singular}, attrs)
      end
    end
    """
  end

  @doc """
  生成 Schema 代码
  """
  def generate_schema(schema_module, table_name, schema_fields) do
    module_name = schema_module |> String.split(".") |> List.last()
    field_defs = generate_schema_fields(schema_fields)
    field_names = schema_fields |> Enum.map(fn f -> ":#{f["name"]}" end) |> Enum.join(", ")
    required = schema_fields |> Enum.filter(& &1["required"]) |> Enum.map(fn f -> ":#{f["name"]}" end) |> Enum.join(", ")
    required_str = if required == "", do: "[]", else: "[#{required}]"

    """
    defmodule #{schema_module} do
      @moduledoc \"\"\"
      #{module_name} Schema
      \"\"\"
      use Ecto.Schema
      import Ecto.Changeset

      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
      schema "#{table_name}" do
        #{field_defs}
        timestamps(type: :utc_datetime)
      end

      def changeset(#{String.downcase(module_name)}, attrs) do
        #{String.downcase(module_name)}
        |> cast(attrs, [#{field_names}])
        |> validate_required(#{required_str})
      end
    end
    """
  end

  @doc """
  生成 Migration 代码
  """
  def generate_migration(table_name, schema_fields) do
    module_name = "Repo.Migrations.Create#{Macro.camelize(table_name)}"
    field_defs = generate_migration_fields(schema_fields)

    """
    defmodule #{module_name} do
      use Ecto.Migration

      def change do
        create table(:#{table_name}, primary_key: false) do
          add :id, :binary_id, primary_key: true
          #{field_defs}
          timestamps(type: :utc_datetime)
        end
      end
    end
    """
  end

  @doc """
  生成 LiveView 代码（简化版）
  """
  def generate_live_view(live_view_module, module_name, _schema_fields) do
    singular = String.downcase(module_name)
    plural = "#{singular}s"

    # 使用 ~S sigil 避免转义问题
    ~S'''
    defmodule MODULE do
      use AdminScaffoldWeb, :live_view

      alias AdminScaffold.MODULES

      @impl true
      def mount(_params, _session, socket) do
        {:ok, stream(socket, :PLURAL, MODULES.list_PLURAL())}
      end

      @impl true
      def handle_info({MODULE.FormComponent, {:saved, _SINGULAR}}, socket) do
        {:noreply, stream(socket, :PLURAL, MODULES.list_PLURAL(), reset: true)}
      end

      @impl true
      def handle_event("delete", %{"id" => id}, socket) do
        SINGULAR = MODULES.get_SINGULAR!(id)
        {:ok, _} = MODULES.delete_SINGULAR(SINGULAR)
        {:noreply, socket |> put_flash(:info, "删除成功") |> stream_delete(:PLURAL, SINGULAR)}
      end

      @impl true
      def render(assigns) do
        ~H"""
        <h1>MODUL ENAME列表</h1>
        <div id={@streams.PLURAL} phx-update="stream">
          <div :for={{dom_id, SINGULAR} <- @streams.PLURAL} id={dom_id}>
            <span>{SINGULAR.id}</span>
            <button phx-click="delete" phx-value-id={SINGULAR.id}>删除</button>
          </div>
        </div>
        """
      end
    end
    '''
    |> String.replace("MODULE", live_view_module)
    |> String.replace("MODULES", "#{module_name}s")
    |> String.replace("MODUL ENAME", module_name)
    |> String.replace("SINGULAR", singular)
    |> String.replace("PLURAL", plural)
  end

  @doc """
  生成测试代码
  """
  def generate_test(context_module, module_name) do
    singular = String.downcase(module_name)

    """
    defmodule #{context_module}Test do
      use AdminScaffold.DataCase

      alias #{context_module}

      describe "#{module_name}s" do
        test "list_#{singular}s/0 returns all #{singular}s" do
          # TODO: 实现测试
        end

        test "get_#{singular}!/1 returns the #{singular} with given id" do
          # TODO: 实现测试
        end

        test "create_#{singular}/1 with valid data creates a #{singular}" do
          # TODO: 实现测试
        end

        test "update_#{singular}/2 with valid data updates the #{singular}" do
          # TODO: 实现测试
        end

        test "delete_#{singular}/1 deletes the #{singular}" do
          # TODO: 实现测试
        end
      end
    end
    """
  end

  # 辅助函数

  defp generate_schema_fields(schema_fields) do
    schema_fields
    |> Enum.map(fn field ->
      "field :#{field["name"]}, #{ecto_type(field["type"])}"
    end)
    |> Enum.join("\n        ")
  end

  defp generate_migration_fields(schema_fields) do
    schema_fields
    |> Enum.map(fn field ->
      "add :#{field["name"]}, #{migration_type(field["type"])}"
    end)
    |> Enum.join("\n          ")
  end

  # 类型映射

  defp ecto_type("string"), do: ":string"
  defp ecto_type("text"), do: ":string"
  defp ecto_type("integer"), do: ":integer"
  defp ecto_type("decimal"), do: ":decimal"
  defp ecto_type("boolean"), do: ":boolean"
  defp ecto_type("date"), do: ":date"
  defp ecto_type("datetime"), do: ":utc_datetime"
  defp ecto_type("time"), do: ":time"
  defp ecto_type("array"), do: "{:array, :string}"
  defp ecto_type("json"), do: ":map"
  defp ecto_type(_), do: ":string"

  defp migration_type("string"), do: ":string"
  defp migration_type("text"), do: ":text"
  defp migration_type("integer"), do: ":integer"
  defp migration_type("decimal"), do: ":decimal"
  defp migration_type("boolean"), do: ":boolean"
  defp migration_type("date"), do: ":date"
  defp migration_type("datetime"), do: ":utc_datetime"
  defp migration_type("time"), do: ":time"
  defp migration_type("array"), do: "{:array, :string}"
  defp migration_type("json"), do: ":map"
  defp migration_type(_), do: ":string"
end
