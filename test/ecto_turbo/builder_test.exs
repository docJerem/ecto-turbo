defmodule EctoTurbo.BuilderTest do
  @moduledoc false

  use ExUnit.Case
  doctest EctoTurbo.Builder

  alias EctoTurbo.Builder
  alias EctoTurbo.Schemas.Post

  describe "run/2 with struct search values" do
    test "keeps a NaiveDateTime value intact" do
      params = %{"q" => %{"inserted_at_lt" => ~N[2024-01-01 00:00:00]}}

      assert Macro.to_string(Builder.run(Post, params)) =~
               "where: p0.inserted_at < ^~N[2024-01-01 00:00:00]"
    end

    test "keeps a Date value intact" do
      params = %{"q" => %{"inserted_at_gt" => ~D[2024-01-01]}}

      assert Macro.to_string(Builder.run(Post, params)) =~
               "where: p0.inserted_at > ^~D[2024-01-01]"
    end

    test "keeps struct values nested in a list intact" do
      params = %{
        "q" => %{"inserted_at_between" => [~N[2024-01-01 00:00:00], ~N[2024-12-31 00:00:00]]}
      }

      query = Macro.to_string(Builder.run(Post, params))

      assert query =~ "^~N[2024-01-01 00:00:00] < p0.inserted_at"
      assert query =~ "p0.inserted_at < ^~N[2024-12-31 00:00:00]"
    end
  end
end
