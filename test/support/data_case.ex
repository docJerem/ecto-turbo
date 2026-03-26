defmodule EctoTurbo.DataCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      import EctoTurbo.TestFactory
    end
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(EctoTurbo.TestRepo)
  end
end
