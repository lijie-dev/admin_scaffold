defmodule AdminScaffold.Repo.Migrations.AddPerformanceIndexes do
  use Ecto.Migration

  def change do
    # 为 permissions 表添加索引
    create_if_not_exists index(:permissions, [:slug])
    create_if_not_exists index(:permissions, [:name])

    # 为 roles 表添加索引
    create_if_not_exists index(:roles, [:name])
    create_if_not_exists index(:roles, [:status])

    # 为 menus 表添加索引
    create_if_not_exists index(:menus, [:path])
    create_if_not_exists index(:menus, [:parent_id])
    create_if_not_exists index(:menus, [:sort])
    create_if_not_exists index(:menus, [:status])

    # 为 audit_logs 表添加索引
    create_if_not_exists index(:audit_logs, [:action])
    create_if_not_exists index(:audit_logs, [:resource])
    create_if_not_exists index(:audit_logs, [:inserted_at])
  end
end
