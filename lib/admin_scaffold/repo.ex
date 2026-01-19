defmodule AdminScaffold.Repo do
  use Ecto.Repo,
    otp_app: :admin_scaffold,
    adapter: Ecto.Adapters.Postgres
end
