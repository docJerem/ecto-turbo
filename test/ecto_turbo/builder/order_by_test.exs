defmodule EctoTurbo.Builder.OrderByTest do
  @moduledoc false

  use ExUnit.Case
  doctest EctoTurbo.Builder.OrderBy

  alias EctoTurbo.Builder.Join
  alias EctoTurbo.Builder.OrderBy
  alias EctoTurbo.Hooks.Search.Attribute
  alias EctoTurbo.Hooks.Sort
  alias EctoTurbo.Schemas.Post

  defp sort(name, direction, parent \\ :query) do
    %Sort{
      attribute: %Attribute{name: name, parent: parent},
      direction: direction
    }
  end

  defp query_binding do
    [Macro.var(:query, Elixir)]
  end

  defp query_with_join_binding do
    [Macro.var(:query, Elixir), Macro.var(:category, Elixir)]
  end

  describe "build/3 single field sort" do
    test "ascending sort" do
      sorts = [sort(:updated_at, :asc)]

      query =
        Post
        |> OrderBy.build(sorts, query_binding())
        |> Macro.to_string()

      assert query ==
               "#Ecto.Query<from p0 in EctoTurbo.Schemas.Post, order_by: [asc: p0.updated_at]>"
    end

    test "descending sort" do
      sorts = [sort(:inserted_at, :desc)]

      query =
        Post
        |> OrderBy.build(sorts, query_binding())
        |> Macro.to_string()

      assert query ==
               "#Ecto.Query<from p0 in EctoTurbo.Schemas.Post, order_by: [desc: p0.inserted_at]>"
    end

    test "sort by name field" do
      sorts = [sort(:name, :asc)]

      query =
        Post
        |> OrderBy.build(sorts, query_binding())
        |> Macro.to_string()

      assert query ==
               "#Ecto.Query<from p0 in EctoTurbo.Schemas.Post, order_by: [asc: p0.name]>"
    end

    test "sort by price field" do
      sorts = [sort(:price, :desc)]

      query =
        Post
        |> OrderBy.build(sorts, query_binding())
        |> Macro.to_string()

      assert query ==
               "#Ecto.Query<from p0 in EctoTurbo.Schemas.Post, order_by: [desc: p0.price]>"
    end
  end

  describe "build/3 multi-field sort" do
    test "two fields same direction" do
      sorts = [sort(:updated_at, :desc), sort(:inserted_at, :desc)]

      query =
        Post
        |> OrderBy.build(sorts, query_binding())
        |> Macro.to_string()

      assert query ==
               "#Ecto.Query<from p0 in EctoTurbo.Schemas.Post, order_by: [desc: p0.updated_at, desc: p0.inserted_at]>"
    end

    test "two fields mixed directions" do
      sorts = [sort(:updated_at, :desc), sort(:name, :asc)]

      query =
        Post
        |> OrderBy.build(sorts, query_binding())
        |> Macro.to_string()

      assert query ==
               "#Ecto.Query<from p0 in EctoTurbo.Schemas.Post, order_by: [desc: p0.updated_at, asc: p0.name]>"
    end

    test "three fields" do
      sorts = [sort(:price, :asc), sort(:name, :desc), sort(:inserted_at, :asc)]

      query =
        Post
        |> OrderBy.build(sorts, query_binding())
        |> Macro.to_string()

      assert query ==
               "#Ecto.Query<from p0 in EctoTurbo.Schemas.Post, order_by: [asc: p0.price, desc: p0.name, asc: p0.inserted_at]>"
    end
  end

  describe "build/3 association sort" do
    test "sort by association field" do
      sorts = [sort(:name, :asc, :category)]

      query =
        Post
        |> Join.build([:category])
        |> OrderBy.build(sorts, query_with_join_binding())
        |> Macro.to_string()

      assert query ==
               "#Ecto.Query<from p0 in EctoTurbo.Schemas.Post, join: c1 in assoc(p0, :category), order_by: [asc: c1.name]>"
    end

    test "mixed main table and association sort" do
      sorts = [sort(:price, :desc), sort(:name, :asc, :category)]

      query =
        Post
        |> Join.build([:category])
        |> OrderBy.build(sorts, query_with_join_binding())
        |> Macro.to_string()

      assert query ==
               "#Ecto.Query<from p0 in EctoTurbo.Schemas.Post, join: c1 in assoc(p0, :category), order_by: [desc: p0.price, asc: c1.name]>"
    end
  end
end
