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
               "where: p0.inserted_at < type(^~N[2024-01-01 00:00:00], p0.inserted_at)"
    end

    test "casts an ISO 8601 string to the column's datetime type" do
      params = %{"q" => %{"inserted_at_gt" => "2024-01-01T00:00:00Z"}}

      assert Macro.to_string(Builder.run(Post, params)) =~
               "where: p0.inserted_at > type(^~N[2024-01-01 00:00:00], p0.inserted_at)"
    end

    test "treats a Date value against a datetime column as midnight" do
      params = %{"q" => %{"inserted_at_gt" => ~D[2024-01-01]}}

      assert Macro.to_string(Builder.run(Post, params)) =~
               "where: p0.inserted_at > type(^~N[2024-01-01 00:00:00], p0.inserted_at)"
    end

    test "keeps struct values nested in a list intact" do
      params = %{
        "q" => %{"inserted_at_between" => [~N[2024-01-01 00:00:00], ~N[2024-12-31 00:00:00]]}
      }

      query = Macro.to_string(Builder.run(Post, params))

      assert query =~ "type(^~N[2024-01-01 00:00:00], p0.inserted_at) < p0.inserted_at"
      assert query =~ "p0.inserted_at < type(^~N[2024-12-31 00:00:00], p0.inserted_at)"
    end
  end
end
