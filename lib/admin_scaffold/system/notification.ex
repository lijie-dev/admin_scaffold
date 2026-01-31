defmodule AdminScaffold.System.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notifications" do
    field :title, :string
    field :message, :string
    field :type, :string
    field :data, :map
    field :read_at, :utc_datetime
    field :read, :boolean, default: false

    belongs_to :user, AdminScaffold.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:title, :message, :type, :data, :user_id, :read, :read_at])
    |> validate_required([:title, :message, :type, :user_id])
    |> foreign_key_constraint(:user_id)
  end
end
