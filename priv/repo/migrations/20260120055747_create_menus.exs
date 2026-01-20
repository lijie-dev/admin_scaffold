defmodule AdminScaffold.Repo.Migrations.CreateMenus do
  use Ecto.Migration

  def change do
    create table(:menus) do
      add :name, :string
      add :path, :string
      add :icon, :string
      add :parent_id, :integer
      add :sort, :integer
      add :status, :integer
      add :user_id, references(:users, type: :id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:menus, [:user_id])
  end
end
