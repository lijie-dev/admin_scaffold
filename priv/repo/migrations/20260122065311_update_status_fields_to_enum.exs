defmodule AdminScaffold.Repo.Migrations.UpdateStatusFieldsToEnum do
  use Ecto.Migration

  def up do
    # 步骤 1: 添加临时字段
    alter table(:roles) do
      add :status_temp, :string
    end

    # 步骤 2: 转换数据到临时字段
    execute """
    UPDATE roles SET status_temp = CASE
      WHEN status = 1 THEN 'active'
      WHEN status = 0 THEN 'inactive'
      ELSE 'active'
    END
    """

    # 步骤 3: 删除旧字段，重命名临时字段
    alter table(:roles) do
      remove :status
    end

    alter table(:roles) do
      add :status, :string, default: "active", null: false
    end

    execute "UPDATE roles SET status = status_temp"

    alter table(:roles) do
      remove :status_temp
    end

    # 对 menus 表执行相同操作
    alter table(:menus) do
      add :status_temp, :string
    end

    execute """
    UPDATE menus SET status_temp = CASE
      WHEN status = 1 THEN 'active'
      WHEN status = 0 THEN 'inactive'
      ELSE 'active'
    END
    """

    alter table(:menus) do
      remove :status
    end

    alter table(:menus) do
      add :status, :string, default: "active", null: false
    end

    execute "UPDATE menus SET status = status_temp"

    alter table(:menus) do
      remove :status_temp
    end
  end

  def down do
    # 回滚 roles 表
    alter table(:roles) do
      add :status_temp, :integer
    end

    execute """
    UPDATE roles SET status_temp = CASE
      WHEN status = 'active' THEN 1
      WHEN status = 'inactive' THEN 0
      ELSE 1
    END
    """

    alter table(:roles) do
      remove :status
    end

    alter table(:roles) do
      add :status, :integer, default: 1, null: false
    end

    execute "UPDATE roles SET status = status_temp"

    alter table(:roles) do
      remove :status_temp
    end

    # 回滚 menus 表
    alter table(:menus) do
      add :status_temp, :integer
    end

    execute """
    UPDATE menus SET status_temp = CASE
      WHEN status = 'active' THEN 1
      WHEN status = 'inactive' THEN 0
      ELSE 1
    END
    """

    alter table(:menus) do
      remove :status
    end

    alter table(:menus) do
      add :status, :integer, default: 1, null: false
    end

    execute "UPDATE menus SET status = status_temp"

    alter table(:menus) do
      remove :status_temp
    end
  end
end
