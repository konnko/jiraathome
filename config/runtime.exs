import Config

if config_env() != :test do
  password =
    System.get_env("APP_PASSWORD") ||
      if config_env() == :dev, do: "dev", else: System.fetch_env!("APP_PASSWORD")

  if password == "", do: raise("APP_PASSWORD must not be empty")
  config :jiraathome, :password, password
end

default_port = if config_env() == :dev, do: "4001", else: "4000"

config :jiraathome, JiraathomeWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT", default_port))]

if config_env() == :prod do
  host = System.get_env("PHX_HOST", "localhost")
  scheme = System.get_env("PHX_SCHEME", "https")

  public_port =
    if scheme == "https", do: 443, else: String.to_integer(System.get_env("PORT", "4000"))

  config :jiraathome, Jiraathome.Repo,
    database: System.get_env("DATABASE_PATH", "/data/jiraathome.db"),
    pool_size: 5

  config :jiraathome, JiraathomeWeb.Endpoint,
    server: true,
    url: [host: host, scheme: scheme, port: public_port],
    http: [ip: {0, 0, 0, 0}],
    secret_key_base: System.fetch_env!("SECRET_KEY_BASE")
end
