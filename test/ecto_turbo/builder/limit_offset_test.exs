defmodule EctoTurbo.Builder.LimitOffsetTest do
  @moduledoc false

  use ExUnit.Case
  doctest EctoTurbo.Builder.LimitOffset

  alias EctoTurbo.Builder.LimitOffset
  alias EctoTurbo.Schemas.Post

  describe "build/4 with :limit" do
    test "applies limit to a queryable" do
      query = LimitOffset.build(:limit, Post, 10, [])
      assert %Ecto.Query{limit: %{expr: 10}} = query
    end

    test "limit of 0" do
      query = LimitOffset.build(:limit, Post, 0, [])
      assert %Ecto.Query{limit: %{expr: 0}} = query
    end

    test "limit of 1" do
      query = LimitOffset.build(:limit, Post, 1, [])
      assert %Ecto.Query{limit: %{expr: 1}} = query
    end

    test "large limit value" do
      query = LimitOffset.build(:limit, Post, 10_000, [])
      assert %Ecto.Query{limit: %{expr: 10_000}} = query
    end

    test "produces correct query string" do
      query = LimitOffset.build(:limit, Post, 5, [])

      assert Macro.to_string(query) ==
               "#Ecto.Query<from p0 in EctoTurbo.Schemas.Post, limit: 5>"
    end
  end

  describe "build/4 with :offset" do
    test "applies offset to a queryable" do
      query = LimitOffset.build(:offset, Post, 20, [])
      assert %Ecto.Query{offset: %{expr: 20}} = query
    end

    test "offset of 0" do
      query = LimitOffset.build(:offset, Post, 0, [])
      assert %Ecto.Query{offset: %{expr: 0}} = query
    end

    test "offset of 1" do
      query = LimitOffset.build(:offset, Post, 1, [])
      assert %Ecto.Query{offset: %{expr: 1}} = query
    end

    test "produces correct query string" do
      query = LimitOffset.build(:offset, Post, 15, [])

      assert Macro.to_string(query) ==
               "#Ecto.Query<from p0 in EctoTurbo.Schemas.Post, offset: 15>"
    end
  end

  describe "build/4 with bindings" do
    test "limit with binding from join" do
      binding = [Macro.var(:query, Elixir), Macro.var(:category, Elixir)]
      query = LimitOffset.build(:limit, Post, 5, binding)
      assert %Ecto.Query{limit: %{expr: 5}} = query
    end

    test "offset with binding from join" do
      binding = [Macro.var(:query, Elixir), Macro.var(:category, Elixir)]
      query = LimitOffset.build(:offset, Post, 10, binding)
      assert %Ecto.Query{offset: %{expr: 10}} = query
    end
  end
end
