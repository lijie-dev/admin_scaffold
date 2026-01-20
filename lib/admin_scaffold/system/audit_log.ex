defmodule AdminScaffold.System.AuditLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "audit_logs" do
    field :action, :string
    field :resource, :string
    field :resource_id, :integer
    field :ip_address, :string
    field :user_agent, :string
    field :details, :map
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(audit_log, attrs) do
    audit_log
    |> cast(attrs, [:action, :resource, :resource_id, :ip_address, :user_agent, :details])
    |> validate_required([:action, :resource, :resource_id, :ip_address, :user_agent])
  end
end
