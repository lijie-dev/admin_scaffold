defmodule AdminScaffold.Accounts.Role do
  use Ecto.Schema
  import Ecto.Changeset

  schema "roles" do
    field :name, :string
    field :description, :string
    field :status, Ecto.Enum, values: [:active, :inactive], default: :active

    many_to_many :users, AdminScaffold.Accounts.User, join_through: "user_roles"
    many_to_many :permissions, AdminScaffold.Accounts.Permission, join_through: "role_permissions"
    many_to_many :menus, AdminScaffold.Accounts.Menu, join_through: "role_menus"

    timestamps(type: :utc_datetime)
  end

  @doc """
  创建或更新角色的 changeset。

  ## 验证规则
  - name: 必填，1-100 字符，唯一
  - description: 可选，最多 500 字符
  - status: 必填，只能是 :active 或 :inactive
  """
  def changeset(role, attrs) do
    role
    |> cast(attrs, [:name, :description, :status])
    |> validate_required([:name, :status])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_length(:description, max: 500)
    |> unique_constraint(:name)
  end
end
