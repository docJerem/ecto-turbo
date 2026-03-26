defmodule EctoTurbo.TestRepo do
  use Ecto.Repo,
    otp_app: :ecto_turbo,
    adapter: Ecto.Adapters.Postgres
end
