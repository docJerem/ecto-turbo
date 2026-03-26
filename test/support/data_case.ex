defmodule EctoTurbo.DataCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox
  alias EctoTurbo.TestRepo

  using do
    quote do
      import EctoTurbo.TestFactory
    end
  end

  setup do
    :ok = Sandbox.checkout(TestRepo)
  end
end
