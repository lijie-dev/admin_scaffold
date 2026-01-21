defmodule AdminScaffold.Repo.Migrations.AddStatusToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :status, :string, default: "active", null: false
    end

    create index(:users, [:status])
  end
end
