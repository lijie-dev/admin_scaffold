defmodule AdminScaffold.Repo.Migrations.CreatePages do
  use Ecto.Migration

  def change do
    create table(:pages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :title, :string, null: false
      add :slug, :string, null: false
      add :type, :string, default: "list", null: false
      add :config, :map, default: "{}"
      add :icon, :string
      add :status, :string, default: "active"
      add :sort, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    create unique_index(:pages, [:slug])
    create index(:pages, [:type])
    create index(:pages, [:status])
  end
end
