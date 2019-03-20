use Mix.Config

config :ecto_ordered, EctoOrderedTest.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  database: "ecto_ordered_test",
  url: System.get_env("DATABASE_URL") || "ecto://postgres:postgres@localhost/ecto_ordered_test",
  priv: "priv/test/repo"
