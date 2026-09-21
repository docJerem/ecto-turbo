defmodule EctoTurbo.TypedValuesTest do
  @moduledoc """
  Guards against compared search values reaching the adapter untyped. The
  where clause builds the field as its own dynamic, which is opaque to the
  comparison, so every value must be explicitly typed against its column for
  Ecto to cast and dump it (UUID strings to 16 bytes, `"1"` to an integer, …).
  """

  use EctoTurbo.DataCase

  alias Ecto.Adapters.SQL
  alias EctoTurbo.Schemas.Post
  alias EctoTurbo.TestRepo

  # Schema-only: the planner resolves the params, no table needed.
  defmodule Resource do
    use Ecto.Schema

    @primary_key {:id, :binary_id, autogenerate: true}
    schema "resources" do
      field(:count, :integer)
      field(:status, Ecto.Enum, values: [draft: 0, published: 1])
    end
  end

  defp params(q) do
    {_sql, params} =
      SQL.to_sql(:all, TestRepo, EctoTurbo.turboq(Resource, %{"q" => q}))

    params
  end

  @uuid "50a13c72-be59-4334-bac8-e0721522256c"
  @raw <<80, 161, 60, 114, 190, 89, 67, 52, 186, 200, 224, 114, 21, 34, 37, 108>>

  describe "values are dumped through the adapter" do
    test "binary_id strings become 16-byte binaries" do
      assert params(%{"id_eq" => @uuid}) == [@raw, 10, 0]
      assert params(%{"id_not_eq" => @uuid}) == [@raw, 10, 0]
      assert params(%{"id_in" => [@uuid]}) == [[@raw], 10, 0]
      assert params(%{"id_not_in" => [@uuid]}) == [[@raw], 10, 0]
    end

    test "integer strings become integers" do
      assert params(%{"count_gt" => "3"}) == [3, 10, 0]
      assert params(%{"count_in" => ["1", "2"]}) == [[1, 2], 10, 0]
      assert params(%{"count_between" => "1..5"}) == [1, 5, 10, 0]
    end

    test "enum atoms become their stored value" do
      assert params(%{"status_eq" => "published"}) == [1, 10, 0]
      assert params(%{"status_in" => ["draft", "published"]}) == [[0, 1], 10, 0]
    end

    test "invalid values raise at query time" do
      assert_raise Ecto.Query.CastError, fn -> params(%{"id_eq" => "not-a-uuid"}) end
      assert_raise Ecto.Query.CastError, fn -> params(%{"count_eq" => "many"}) end
    end
  end

  describe "against the database" do
    test "string params on an integer column" do
      insert(:post, name: "few", replies_count: 1)
      insert(:post, name: "many", replies_count: 9)

      names = fn q ->
        Post |> EctoTurbo.turboq(%{"q" => q}) |> TestRepo.all() |> Enum.map(& &1.name)
      end

      assert names.(%{"replies_count_eq" => "9"}) == ["many"]
      assert names.(%{"replies_count_in" => ["1"]}) == ["few"]
      assert names.(%{"replies_count_between" => "0..5"}) == ["few"]
    end
  end
end
