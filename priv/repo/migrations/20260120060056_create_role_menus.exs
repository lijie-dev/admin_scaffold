defmodule AdminScaffold.Repo.Migrations.CreateRoleMenus do
  use Ecto.Migration

  def change do
    create table(:role_menus) do
      add :role_id, references(:roles, on_delete: :delete_all), null: false
      add :menu_id, references(:menus, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:role_menus, [:role_id])
    create index(:role_menus, [:menu_id])
    create unique_index(:role_menus, [:role_id, :menu_id])
  end
end
