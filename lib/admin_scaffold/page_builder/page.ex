defmodule AdminScaffold.PageBuilder.Page do
  @moduledoc """
  页面配置 Schema，用于存储 JSON 驱动的页面定义
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "pages" do
    field :name, :string
    field :title, :string
    field :slug, :string
    field :type, :string, default: "list"  # list, form, detail, dashboard
    field :config, :map                    # JSON 配置
    field :icon, :string
    field :status, :string, default: "active"  # active, inactive
    field :sort, :integer, default: 0

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating/updating pages.
  """
  def changeset(page, attrs) do
    page
    |> cast(attrs, [:name, :title, :slug, :type, :config, :icon, :status, :sort])
    |> validate_required([:name, :title, :slug, :type])
    |> validate_inclusion(:type, ["list", "form", "detail", "dashboard"])
    |> validate_inclusion(:status, ["active", "inactive"])
    |> unique_constraint(:slug)
  end
end
