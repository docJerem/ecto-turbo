defmodule EctoTurbo.Builder.WhereTest do
  @moduledoc false

  use ExUnit.Case
  doctest EctoTurbo.Builder.Where

  alias EctoTurbo.Builder.{Join, Where}
  alias EctoTurbo.Hooks.Search
  alias EctoTurbo.Hooks.Search.{Attribute, Condition}
  alias EctoTurbo.Schemas.Post

  defp attr(name, parent \\ :query), do: %Attribute{name: name, parent: parent}

  defp condition(attrs, search_type, values, combinator \\ :and) do
    %Condition{
      attributes: attrs,
      search_type: search_type,
      values: values,
      combinator: combinator
    }
  end

  defp search(conditions, combinator \\ :and) do
    %Search{conditions: conditions, combinator: combinator, groupings: []}
  end

  defp query_binding, do: [Macro.var(:query, Elixir)]

  defp query_with_join_binding do
    [Macro.var(:query, Elixir), Macro.var(:category, Elixir)]
  end

  defp build_query_string(conditions, combinator \\ :and) do
    search = search(conditions, combinator)

    Post
    |> Where.build(search, query_binding())
    |> Macro.to_string()
  end

  describe "build/3 single condition" do
    test "eq search type" do
      query = build_query_string([condition([attr(:price)], :eq, [100])])

      assert query ==
               "#Ecto.Query<from p0 in EctoTurbo.Schemas.Post, where: p0.price == ^100>"
    end

    test "not_eq search type" do
      query = build_query_string([condition([attr(:price)], :not_eq, [100])])

      assert query ==
               "#Ecto.Query<from p0 in EctoTurbo.Schemas.Post, where: p0.price != ^100>"
    end

    test "lt search type" do
      query = build_query_string([condition([attr(:price)], :lt, [50])])

      assert query ==
               "#Ecto.Query<from p0 in EctoTurbo.Schemas.Post, where: p0.price < ^50>"
    end

    test "lteq search type" do
      query = build_query_string([condition([attr(:price)], :lteq, [50])])

      assert query ==
               "#Ecto.Query<from p0 in EctoTurbo.Schemas.Post, where: p0.price <= ^50>"
    end

    test "gt search type" do
      query = build_query_string([condition([attr(:price)], :gt, [50])])

      assert query ==
               "#Ecto.Query<from p0 in EctoTurbo.Schemas.Post, where: p0.price > ^50>"
    end

    test "gteq search type" do
      query = build_query_string([condition([attr(:price)], :gteq, [50])])

      assert query ==
               "#Ecto.Query<from p0 in EctoTurbo.Schemas.Post, where: p0.price >= ^50>"
    end

    test "like search type" do
      query = build_query_string([condition([attr(:name)], :like, ["elixir"])])

      assert query ==
               "#Ecto.Query<from p0 in EctoTurbo.Schemas.Post, where: like(p0.name, ^\"%elixir%\")>"
    end

    test "not_like search type" do
      query = build_query_string([condition([attr(:name)], :not_like, ["elixir"])])

      assert query ==
               "#Ecto.Query<from p0 in EctoTurbo.Schemas.Post, where: not like(p0.name, ^\"%elixir%\")>"
    end

    test "ilike search type" do
      query = build_query_string([condition([attr(:name)], :ilike, ["elixir"])])

      assert query ==
               "#Ecto.Query<from p0 in EctoTurbo.Schemas.Post, where: ilike(p0.name, ^\"%elixir%\")>"
    end

    test "not_ilike search type" do
      query = build_query_string([condition([attr(:name)], :not_ilike, ["elixir"])])

      assert query ==
               "#Ecto.Query<from p0 in EctoTurbo.Schemas.Post, where: not ilike(p0.name, ^\"%elixir%\")>"
    end

    test "in search type" do
      query = build_query_string([condition([attr(:price)], :in, [10, 20])])

      assert query ==
               "#Ecto.Query<from p0 in EctoTurbo.Schemas.Post, where: p0.price in ^[10, 20]>"
    end

    test "not_in search type" do
      query = build_query_string([condition([attr(:price)], :not_in, [10, 20])])

      assert query ==
               "#Ecto.Query<from p0 in EctoTurbo.Schemas.Post, where: p0.price not in ^[10, 20]>"
    end

    test "start_with search type" do
      query = build_query_string([condition([attr(:name)], :start_with, ["post"])])

      assert query ==
               "#Ecto.Query<from p0 in EctoTurbo.Schemas.Post, where: ilike(p0.name, ^\"post%\")>"
    end

    test "end_with search type" do
      query = build_query_string([condition([attr(:name)], :end_with, ["post"])])

      assert query ==
               "#Ecto.Query<from p0 in EctoTurbo.Schemas.Post, where: ilike(p0.name, ^\"%post\")>"
    end

    test "is_null search type with true" do
      query = build_query_string([condition([attr(:name)], :is_null, [true])])

      assert query ==
               "#Ecto.Query<from p0 in EctoTurbo.Schemas.Post, where: is_nil(p0.name)>"
    end

    test "is_null search type with false" do
      query = build_query_string([condition([attr(:name)], :is_null, [false])])

      assert query ==
               "#Ecto.Query<from p0 in EctoTurbo.Schemas.Post, where: not is_nil(p0.name)>"
    end

    test "is_true search type" do
      query = build_query_string([condition([attr(:available)], :is_true, [true])])

      assert query ==
               "#Ecto.Query<from p0 in EctoTurbo.Schemas.Post, where: p0.available == ^true>"
    end

    test "is_false search type" do
      query = build_query_string([condition([attr(:available)], :is_false, [true])])

      assert query ==
               "#Ecto.Query<from p0 in EctoTurbo.Schemas.Post, where: p0.available == ^false>"
    end

    test "between search type" do
      query = build_query_string([condition([attr(:price)], :between, ["10", "20"])])

      assert query ==
               "#Ecto.Query<from p0 in EctoTurbo.Schemas.Post, where: ^\"10\" < p0.price and p0.price < ^\"20\">"
    end
  end

  describe "build/3 with AND combinator" do
    test "two AND conditions" do
      conditions = [
        condition([attr(:price)], :eq, [100]),
        condition([attr(:name)], :like, ["elixir"])
      ]

      query = build_query_string(conditions, :and)

      assert query =~ "p0.price == ^100"
      assert query =~ "like(p0.name, ^\"%elixir%\")"
    end

    test "three AND conditions" do
      conditions = [
        condition([attr(:price)], :gt, [10]),
        condition([attr(:name)], :like, ["post"]),
        condition([attr(:available)], :is_true, [true])
      ]

      query = build_query_string(conditions, :and)

      assert query =~ "p0.price > ^10"
      assert query =~ "like(p0.name, ^\"%post%\")"
      assert query =~ "p0.available == ^true"
    end
  end

  describe "build/3 with OR combinator within condition" do
    test "OR between two fields" do
      cond_or =
        condition(
          [attr(:name), attr(:body)],
          :like,
          ["elixir"],
          :or
        )

      query = build_query_string([cond_or])

      assert query =~ "like(p0.name, ^\"%elixir%\") or like(p0.body, ^\"%elixir%\")"
    end
  end

  describe "build/3 with association fields" do
    test "where on association field" do
      cond_assoc = condition([attr(:name, :category)], :like, ["tech"])
      search_struct = search([cond_assoc])

      query =
        Post
        |> Join.build([:category])
        |> Where.build(search_struct, query_with_join_binding())
        |> Macro.to_string()

      assert query =~ "like(c1.name, ^\"%tech%\")"
    end

    test "where on mixed main and association fields" do
      cond_main = condition([attr(:price)], :gt, [10])
      cond_assoc = condition([attr(:name, :category)], :eq, ["tech"])
      search_struct = search([cond_main, cond_assoc])

      query =
        Post
        |> Join.build([:category])
        |> Where.build(search_struct, query_with_join_binding())
        |> Macro.to_string()

      assert query =~ "p0.price > ^10"
      assert query =~ "c1.name == ^\"tech\""
    end

    test "OR between main and association field" do
      cond_or =
        condition(
          [attr(:name), attr(:name, :category)],
          :like,
          ["elixir"],
          :or
        )

      search_struct = search([cond_or])

      query =
        Post
        |> Join.build([:category])
        |> Where.build(search_struct, query_with_join_binding())
        |> Macro.to_string()

      assert query =~ "like(p0.name, ^\"%elixir%\") or like(c1.name, ^\"%elixir%\")"
    end
  end

  describe "build/3 returns valid Ecto.Query" do
    test "result is an Ecto.Query struct" do
      cond_eq = condition([attr(:price)], :eq, [100])
      search_struct = search([cond_eq])

      query = Where.build(Post, search_struct, query_binding())
      assert %Ecto.Query{} = query
    end

    test "result has wheres populated" do
      cond_eq = condition([attr(:price)], :eq, [100])
      search_struct = search([cond_eq])

      query = Where.build(Post, search_struct, query_binding())
      assert length(query.wheres) == 1
    end
  end
end
