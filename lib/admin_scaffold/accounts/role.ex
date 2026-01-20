defmodule AdminScaffold.Accounts.Role do
  use Ecto.Schema
  import Ecto.Changeset

  schema "roles" do
    field :name, :string
    field :description, :string
    field :status, :integer

    many_to_many :users, AdminScaffold.Accounts.User, join_through: "user_roles"
    many_to_many :permissions, AdminScaffold.Accounts.Permission, join_through: "role_permissions"
    many_to_many :menus, AdminScaffold.Accounts.Menu, join_through: "role_menus"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(role, attrs) do
    role
    |> cast(attrs, [:name, :description, :status])
    |> validate_required([:name, :status])
    |> unique_constraint(:name)
  end
end
