defmodule AdminScaffold.Repo.Migrations.AddIndexesToAssociationTables do
  use Ecto.Migration

  def change do
    # Add indexes to user_roles table
    create_if_not_exists index(:user_roles, [:user_id])
    create_if_not_exists index(:user_roles, [:role_id])
    create_if_not_exists index(:user_roles, [:user_id, :role_id], unique: true)

    # Add indexes to role_permissions table
    create_if_not_exists index(:role_permissions, [:role_id])
    create_if_not_exists index(:role_permissions, [:permission_id])
    create_if_not_exists index(:role_permissions, [:role_id, :permission_id], unique: true)

    # Add indexes to role_menus table
    create_if_not_exists index(:role_menus, [:role_id])
    create_if_not_exists index(:role_menus, [:menu_id])
    create_if_not_exists index(:role_menus, [:role_id, :menu_id], unique: true)
  end
end
