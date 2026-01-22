defmodule AdminScaffold.Accounts.Menu do
  use Ecto.Schema
  import Ecto.Changeset

  schema "menus" do
    field :name, :string
    field :path, :string
    field :icon, :string
    field :parent_id, :integer
    field :sort, :integer
    field :status, Ecto.Enum, values: [:active, :inactive], default: :active

    many_to_many :roles, AdminScaffold.Accounts.Role, join_through: "role_menus"

    timestamps(type: :utc_datetime)
  end

  @doc """
  创建或更新菜单的 changeset。

  ## 验证规则
  - name: 必填，1-100 字符
  - path: 必填，1-200 字符，必须以 / 开头
  - icon: 可选，最多 100 字符
  - parent_id: 可选，父菜单 ID
  - sort: 必填，排序值（0-9999）
  - status: 必填，只能是 :active 或 :inactive
  """
  def changeset(menu, attrs) do
    menu
    |> cast(attrs, [:name, :path, :icon, :parent_id, :sort, :status])
    |> validate_required([:name, :path, :sort, :status])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_length(:path, min: 1, max: 200)
    |> validate_length(:icon, max: 100)
    |> validate_format(:path, ~r/^\//, message: "路径必须以 / 开头")
    |> validate_number(:sort, greater_than_or_equal_to: 0, less_than: 10000)
  end
end
