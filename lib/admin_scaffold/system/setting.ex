defmodule AdminScaffold.System.Setting do
  use Ecto.Schema
  import Ecto.Changeset

  schema "settings" do
    field :key, :string
    field :value, :string
    field :description, :string
    field :type, :string
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(setting, attrs, user_scope) do
    setting
    |> cast(attrs, [:key, :value, :description, :type])
    |> validate_required([:key, :value, :description, :type])
    |> put_change(:user_id, user_scope.user.id)
  end
end
