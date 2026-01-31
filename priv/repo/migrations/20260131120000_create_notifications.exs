defmodule AdminScaffold.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def change do
    create table(:notifications) do
      add :title, :string, null: false
      add :message, :string, null: false
      add :type, :string, null: false
      add :data, :map, default: %{}
      add :read, :boolean, default: false
      add :read_at, :utc_datetime
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:notifications, [:user_id])
    create index(:notifications, [:read])
    create index(:notifications, [:inserted_at])
  end
end
