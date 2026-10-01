import Config

config :jiraathome, Jiraathome.Repo,
  database: Path.expand("../jiraathome_dev.db", __DIR__),
  pool_size: 5

config :jiraathome, JiraathomeWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "V2PZBct5k7LDIV6sCddSNH0QeMaojpMse0xXBIs6c0h1NUpTU9yZTnnV3rAnsefb",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:jiraathome, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:jiraathome, ~w(--watch)]}
  ],
  live_reload: [
    patterns: [~r"priv/static/.*$", ~r"lib/jiraathome_web/.*(ex|heex)$"]
  ]

config :logger, :default_formatter, format: "[$level] $message\n"
config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  debug_heex_annotations: true,
  debug_attributes: true
