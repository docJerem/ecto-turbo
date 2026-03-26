import Config

config :ecto_turbo, EctoTurbo,
  repo: EctoTurbo.TestRepo,
  per_page: 10

config :ecto_turbo, ecto_repos: [EctoTurbo.TestRepo]

config :ecto_turbo, EctoTurbo.TestRepo,
  username: "postgres",
  password: "postgres",
  database: "ecto_turbo_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :logger, level: :warning
