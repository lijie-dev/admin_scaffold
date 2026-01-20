defmodule AdminScaffold.Accounts.Menu do
  use Ecto.Schema
  import Ecto.Changeset

  schema "menus" do
    field :name, :string
    field :path, :string
    field :icon, :string
    field :parent_id, :integer
    field :sort, :integer
    field :status, :integer

    many_to_many :roles, AdminScaffold.Accounts.Role, join_through: "role_menus"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(menu, attrs) do
    menu
    |> cast(attrs, [:name, :path, :icon, :parent_id, :sort, :status])
    |> validate_required([:name, :path, :sort, :status])
  end
end
