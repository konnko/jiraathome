# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :ash, default_string_length_count: :codepoints

config :jiraathome,
  ecto_repos: [Jiraathome.Repo],
  ash_domains: [Jiraathome.Login, Jiraathome.Board, Jiraathome.Files, Jiraathome.Documents],
  generators: [timestamp_type: :utc_datetime]

config :jiraathome, Jiraathome.Repo,
  default_transaction_mode: :immediate,
  timeout: 15_000,
  busy_timeout: 16_000

config :jiraathome, Oban,
  repo: Jiraathome.Repo,
  engine: Oban.Engines.Lite,
  notifier: Oban.Notifiers.Isolated,
  queues: [maintenance: 1],
  plugins: [
    {Oban.Plugins.Cron, crontab: [{"0 3 * * 0", Jiraathome.Files.UnreferencedFilesCleanupJob}]}
  ]

# Configure the endpoint
config :jiraathome, JiraathomeWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: JiraathomeWeb.ErrorHTML, json: JiraathomeWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Jiraathome.PubSub,
  live_view: [signing_salt: "XtDZl5Vr"]

# Configure LiveView
config :phoenix_live_view,
  # the attribute set on all root tags. Used for Phoenix.LiveView.ColocatedCSS.
  root_tag_attribute: "phx-r"

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  jiraathome: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=. --loader:.woff2=file --loader:.woff=file --loader:.ttf=file --asset-names=fonts/[name]-[hash]),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.2.3",
  jiraathome: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
