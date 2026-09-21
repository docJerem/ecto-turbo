defmodule EctoTurbo.EnumCoercionTest do
  @moduledoc """
  Guards against `Ecto.Enum` search values reaching the database as raw
  strings (e.g. `"published"`): they are cast to the enum atom up front so
  invalid values raise a clear error, and typed against the column so the
  adapter dumps them to the stored representation (the integer `1`).
  """

  use EctoTurbo.DataCase

  alias EctoTurbo.Hooks.Search.Attribute
  alias EctoTurbo.Schemas.{Category, Post}
  alias EctoTurbo.Services.BuildSearchQuery
  alias EctoTurbo.TestRepo

  defp status_attribute do
    %Attribute{name: :status, parent: :category, type: Category.__schema__(:type, :status)}
  end

  describe "coerce_values/3" do
    test "casts enum string values to their atom representation" do
      assert BuildSearchQuery.coerce_values(:in, status_attribute(), ["published"]) == [
               :published
             ]

      assert BuildSearchQuery.coerce_values(:eq, status_attribute(), ["draft"]) == [:draft]
    end

    test "leaves untyped attributes untouched" do
      attribute = %Attribute{name: :name, parent: :query, type: nil}

      assert BuildSearchQuery.coerce_values(:eq, attribute, ["elixir"]) == ["elixir"]
    end

    test "leaves pattern and predicate search types untouched" do
      assert BuildSearchQuery.coerce_values(:like, status_attribute(), ["pub"]) == ["pub"]
      assert BuildSearchQuery.coerce_values(:is_null, status_attribute(), ["true"]) == ["true"]
    end

    test "splits the `begin..end` between form before coercing" do
      assert BuildSearchQuery.coerce_values(:between, status_attribute(), ["draft..published"]) ==
               [:draft, :published]
    end

    test "raises a clear error when the value cannot be cast to the enum" do
      assert_raise ArgumentError,
                   ~s(invalid search value "nope" for attribute :status, expected one of [:draft, :published]),
                   fn -> BuildSearchQuery.coerce_values(:eq, status_attribute(), ["nope"]) end
    end
  end

  describe "Attribute.extract/2" do
    test "resolves the Ecto.Enum type for direct and associated fields" do
      assert %Attribute{parent: :query, type: {:parameterized, {Ecto.Enum, _}}} =
               Attribute.extract("status", Category)

      assert %Attribute{parent: :category, type: {:parameterized, {Ecto.Enum, _}}} =
               Attribute.extract("category_status", Post)
    end

    test "leaves the type nil for plain fields" do
      assert %Attribute{type: nil} = Attribute.extract("name", Post)
      assert %Attribute{type: nil} = Attribute.extract("category_name", Post)
    end
  end

  describe "filtering by an associated Ecto.Enum field" do
    setup do
      published = insert(:category, status: :published)
      draft = insert(:category, status: :draft)

      insert(:post, name: "published-post", category: published)
      insert(:post, name: "draft-post", category: draft)

      :ok
    end

    defp search_names(q) do
      Post
      |> EctoTurbo.turboq(%{"q" => q})
      |> TestRepo.all()
      |> Enum.map(& &1.name)
      |> Enum.sort()
    end

    test "matches on the enum string value without crashing the adapter" do
      assert search_names(%{"category_status_in" => ["published"]}) == ["published-post"]
      assert search_names(%{"category_status_eq" => "draft"}) == ["draft-post"]
      assert search_names(%{"category_status_not_eq" => "draft"}) == ["published-post"]
    end

    test "supports the `begin..end` between form" do
      assert search_names(%{"category_status_between" => "draft..published"}) == []
    end

    test "still supports predicate search types on the enum column" do
      assert search_names(%{"category_status_is_null" => "true"}) == []

      assert search_names(%{"category_status_is_null" => "false"}) ==
               ["draft-post", "published-post"]
    end

    test "raises on an invalid enum value instead of failing at the adapter" do
      assert_raise ArgumentError, ~r/invalid search value "nope"/, fn ->
        search_names(%{"category_status_eq" => "nope"})
      end
    end
  end
end
