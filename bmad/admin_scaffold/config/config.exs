# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :admin_scaffold, :scopes,
  user: [
    default: true,
    module: AdminScaffold.Accounts.Scope,
    assign_key: :current_scope,
    access_path: [:user, :id],
    schema_key: :user_id,
    schema_type: :id,
    schema_table: :users,
    test_data_fixture: AdminScaffold.AccountsFixtures,
    test_setup_helper: :register_and_log_in_user
  ]

config :admin_scaffold,
  ecto_repos: [AdminScaffold.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configure the endpoint
config :admin_scaffold, AdminScaffoldWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: AdminScaffoldWeb.ErrorHTML, json: AdminScaffoldWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: AdminScaffold.PubSub,
  live_view: [signing_salt: "FUI+l+/T"]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  admin_scaffold: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.0",
  admin_scaffold: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]
