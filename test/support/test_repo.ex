defmodule EctoTurbo.TestRepo do
  @moduledoc false
  use Ecto.Repo,
    otp_app: :ecto_turbo,
    adapter: Ecto.Adapters.Postgres
end
