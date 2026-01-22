defmodule AdminScaffold.System.AuditLog do
  @moduledoc """
  审计日志 schema,用于记录系统中的关键操作。
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias AdminScaffold.Accounts.User

  @valid_actions ~w(create update delete login logout)

  schema "audit_logs" do
    field :action, :string
    field :resource, :string
    field :resource_id, :integer
    field :ip_address, :string
    field :user_agent, :string
    field :details, :map

    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(audit_log, attrs) do
    audit_log
    |> cast(attrs, [
      :action,
      :resource,
      :resource_id,
      :ip_address,
      :user_agent,
      :details,
      :user_id
    ])
    |> validate_required([:action, :resource])
    |> validate_inclusion(:action, @valid_actions)
    |> foreign_key_constraint(:user_id)
  end
end
