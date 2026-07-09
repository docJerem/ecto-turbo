defmodule EctoTurbo.EnumCoercionTest do
  @moduledoc """
  Guards against `Ecto.Enum` search values reaching the database in their cast
  form (e.g. the string `"published"`) instead of their dumped representation
  (the integer `1`), which the adapter rejects for the underlying column.
  """

  use EctoTurbo.DataCase

  alias EctoTurbo.Schemas.{Category, Post}
  alias EctoTurbo.Services.BuildSearchQuery
  alias EctoTurbo.Hooks.Search.Attribute
  alias EctoTurbo.TestRepo

  describe "coerce_values/2" do
    test "dumps enum string values to their stored representation" do
      type = Category.__schema__(:type, :status)
      attribute = %Attribute{name: :status, parent: :category, type: type}

      assert BuildSearchQuery.coerce_values(attribute, ["published"]) == [1]
    end

    test "leaves untyped attributes untouched" do
      attribute = %Attribute{name: :name, parent: :query, type: nil}

      assert BuildSearchQuery.coerce_values(attribute, ["elixir"]) == ["elixir"]
    end

    test "falls back to the raw value when it cannot be cast to the enum" do
      type = Category.__schema__(:type, :status)
      attribute = %Attribute{name: :status, parent: :category, type: type}

      assert BuildSearchQuery.coerce_values(attribute, ["nope"]) == ["nope"]
    end
  end

  describe "filtering by an associated Ecto.Enum field" do
    test "matches on the enum string value without crashing the adapter" do
      published = insert(:category, status: :published)
      draft = insert(:category, status: :draft)

      insert(:post, name: "published-post", category: published)
      insert(:post, name: "draft-post", category: draft)

      names =
        Post
        |> EctoTurbo.turboq(%{"q" => %{"category_status_in" => ["published"]}})
        |> TestRepo.all()
        |> Enum.map(& &1.name)

      assert names == ["published-post"]
    end
  end
end
