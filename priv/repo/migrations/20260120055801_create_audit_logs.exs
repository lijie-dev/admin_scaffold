defmodule AdminScaffold.Repo.Migrations.CreateAuditLogs do
  use Ecto.Migration

  def change do
    create table(:audit_logs) do
      add :action, :string
      add :resource, :string
      add :resource_id, :integer
      add :ip_address, :string
      add :user_agent, :text
      add :details, :map
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:audit_logs, [:user_id])
  end
end
