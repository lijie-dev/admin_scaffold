defmodule AdminScaffold.Accounts.Permission do
  use Ecto.Schema
  import Ecto.Changeset

  schema "permissions" do
    field :name, :string
    field :slug, :string
    field :description, :string

    many_to_many :roles, AdminScaffold.Accounts.Role, join_through: "role_permissions"

    timestamps(type: :utc_datetime)
  end

  @doc """
  创建或更新权限的 changeset。

  ## 验证规则
  - name: 必填，1-100 字符
  - slug: 必填，1-100 字符，唯一，只能包含小写字母、数字和连字符
  - description: 可选，最多 500 字符
  """
  def changeset(permission, attrs) do
    permission
    |> cast(attrs, [:name, :slug, :description])
    |> validate_required([:name, :slug])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_length(:slug, min: 1, max: 100)
    |> validate_length(:description, max: 500)
    |> validate_format(:slug, ~r/^[a-z0-9]+(?:-[a-z0-9]+)*$/,
      message: "只能包含小写字母、数字和连字符，且不能以连字符开头或结尾"
    )
    |> unique_constraint(:slug)
  end
end
