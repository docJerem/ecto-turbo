defmodule EctoTurbo.TemporalCoercionTest do
  @moduledoc """
  Guards against date/time search values reaching the adapter as raw strings.
  The where clause compares through an interpolated `field/2`, so Ecto cannot
  infer the parameter type: values must be cast to the column type up front.
  """

  use EctoTurbo.DataCase

  alias EctoTurbo.Hooks.Search.Attribute
  alias EctoTurbo.Schemas.Post
  alias EctoTurbo.Services.BuildSearchQuery
  alias EctoTurbo.TestRepo

  # Schema-only module covering every temporal type; never hits the database.
  defmodule Event do
    use Ecto.Schema

    schema "events" do
      field(:name, :string)
      field(:on_date, :date)
      field(:at_time, :time)
      field(:at_time_usec, :time_usec)
      field(:naive_at, :naive_datetime)
      field(:naive_usec_at, :naive_datetime_usec)
      field(:utc_at, :utc_datetime)
      field(:utc_usec_at, :utc_datetime_usec)
    end
  end

  defp attribute(field) do
    %Attribute{name: field, parent: :query, type: Event.__schema__(:type, field)}
  end

  defp coerce(field, value, search_type \\ :eq),
    do: BuildSearchQuery.coerce_values(search_type, attribute(field), List.wrap(value))

  describe "Attribute.extract/2" do
    test "resolves every temporal type on direct fields" do
      for {key, type} <- [
            {"on_date", :date},
            {"at_time", :time},
            {"at_time_usec", :time_usec},
            {"naive_at", :naive_datetime},
            {"naive_usec_at", :naive_datetime_usec},
            {"utc_at", :utc_datetime},
            {"utc_usec_at", :utc_datetime_usec}
          ] do
        assert %Attribute{parent: :query, type: ^type} = Attribute.extract(key, Event)
      end
    end

    test "leaves non temporal fields untyped" do
      assert %Attribute{type: nil} = Attribute.extract("name", Event)
    end

    test "resolves the temporal type through an association" do
      assert %Attribute{parent: :category, type: :naive_datetime} =
               Attribute.extract("category_inserted_at", Post)
    end
  end

  describe "coerce_values/3 with ISO 8601 strings" do
    test "casts to the column type" do
      assert coerce(:on_date, "2024-01-01") == [~D[2024-01-01]]
      assert coerce(:at_time, "10:30:00") == [~T[10:30:00]]
      assert coerce(:naive_at, "2024-01-01 10:30:00") == [~N[2024-01-01 10:30:00]]
      assert coerce(:naive_at, "2024-01-01T10:30:00Z") == [~N[2024-01-01 10:30:00]]
      assert coerce(:utc_at, "2024-01-01T10:30:00Z") == [~U[2024-01-01 10:30:00Z]]
    end

    test "normalises utc datetimes with an offset to UTC" do
      assert coerce(:utc_at, "2024-01-01T10:30:00+02:00") == [~U[2024-01-01 08:30:00Z]]
    end

    test "keeps microseconds only on usec columns" do
      assert coerce(:naive_at, "2024-01-01 10:30:00.123456") == [~N[2024-01-01 10:30:00]]

      assert coerce(:naive_usec_at, "2024-01-01 10:30:00.123456") ==
               [~N[2024-01-01 10:30:00.123456]]

      assert coerce(:utc_usec_at, "2024-01-01T10:30:00.123456Z") ==
               [~U[2024-01-01 10:30:00.123456Z]]

      assert coerce(:at_time_usec, "10:30:00.123456") == [~T[10:30:00.123456]]
    end

    test "handles every comparison search type" do
      for search_type <- ~w(eq not_eq lt lteq gt gteq in not_in)a do
        assert coerce(:on_date, "2024-01-01", search_type) == [~D[2024-01-01]]
      end

      assert coerce(:on_date, ["2024-01-01", "2024-12-31"], :in) ==
               [~D[2024-01-01], ~D[2024-12-31]]
    end

    test "supports both between forms" do
      assert coerce(:on_date, "2024-01-01..2024-12-31", :between) ==
               [~D[2024-01-01], ~D[2024-12-31]]

      assert coerce(:naive_at, ["2024-01-01T00:00:00Z", "2024-12-31T00:00:00Z"], :between) ==
               [~N[2024-01-01 00:00:00], ~N[2024-12-31 00:00:00]]
    end
  end

  describe "coerce_values/3 with structs" do
    test "passes matching structs through" do
      assert coerce(:on_date, ~D[2024-01-01]) == [~D[2024-01-01]]
      assert coerce(:at_time, ~T[10:30:00]) == [~T[10:30:00]]
      assert coerce(:naive_at, ~N[2024-01-01 10:30:00]) == [~N[2024-01-01 10:30:00]]
      assert coerce(:utc_at, ~U[2024-01-01 10:30:00Z]) == [~U[2024-01-01 10:30:00Z]]
    end

    test "converts between datetime flavours" do
      assert coerce(:utc_at, ~N[2024-01-01 10:30:00]) == [~U[2024-01-01 10:30:00Z]]
      assert coerce(:naive_at, ~U[2024-01-01 10:30:00Z]) == [~N[2024-01-01 10:30:00]]
    end

    test "truncates a datetime to a date column" do
      assert coerce(:on_date, ~N[2024-01-01 10:30:00]) == [~D[2024-01-01]]
    end
  end

  describe "date-only values against datetime columns" do
    test "are taken as midnight" do
      assert coerce(:naive_at, "2024-01-01") == [~N[2024-01-01 00:00:00]]
      assert coerce(:naive_at, ~D[2024-01-01]) == [~N[2024-01-01 00:00:00]]
      assert coerce(:naive_usec_at, "2024-01-01") == [~N[2024-01-01 00:00:00.000000]]
      assert coerce(:utc_at, "2024-01-01") == [~U[2024-01-01 00:00:00Z]]
      assert coerce(:utc_usec_at, ~D[2024-01-01]) == [~U[2024-01-01 00:00:00.000000Z]]
    end

    test "do not apply to date or time columns" do
      assert_raise ArgumentError, fn -> coerce(:on_date, "10:30:00") end
      assert_raise ArgumentError, fn -> coerce(:at_time, "2024-01-01") end
    end
  end

  describe "coerce_values/3 invalid values" do
    test "raise with the attribute and expected type" do
      assert_raise ArgumentError,
                   ~s(invalid search value "yesterday" for attribute :on_date, expected a value of type :date),
                   fn -> coerce(:on_date, "yesterday") end

      assert_raise ArgumentError, fn -> coerce(:naive_at, "2024-13-01") end
      assert_raise ArgumentError, fn -> coerce(:naive_at, "10000-01-01 00:00:00") end
      assert_raise ArgumentError, fn -> coerce(:naive_at, 20_240_101) end
      assert_raise ArgumentError, fn -> coerce(:at_time, ~D[2024-01-01]) end
    end
  end

  describe "non comparison search types" do
    test "leave temporal values untouched" do
      assert coerce(:naive_at, "2024", :like) == ["2024"]
      assert coerce(:naive_at, "true", :is_null) == ["true"]
      assert coerce(:naive_at, "2024-01", :start_with) == ["2024-01"]
    end
  end

  describe "filtering by a datetime field through an association" do
    setup do
      old = insert(:category, name: "old", inserted_at: ~N[2000-06-01 12:00:00])
      new = insert(:category, name: "new", inserted_at: ~N[2030-06-01 12:00:00])

      insert(:post, name: "old-post", category: old)
      insert(:post, name: "new-post", category: new)

      :ok
    end

    defp search_names(q) do
      Post
      |> EctoTurbo.turboq(%{"q" => q})
      |> TestRepo.all()
      |> Enum.map(& &1.name)
      |> Enum.sort()
    end

    test "compares chronologically, not lexicographically" do
      assert search_names(%{"category_inserted_at_lt" => "2010-01-01"}) == ["old-post"]

      assert search_names(%{"category_inserted_at_gteq" => "2010-01-01T00:00:00Z"}) == [
               "new-post"
             ]

      assert search_names(%{"category_inserted_at_eq" => ~N[2030-06-01 12:00:00]}) == ["new-post"]

      assert search_names(%{"category_inserted_at_between" => "2000-01-01..2001-01-01"}) ==
               ["old-post"]

      assert search_names(%{
               "category_inserted_at_in" => ["2000-06-01T12:00:00Z", "2030-06-01T12:00:00Z"]
             }) == ["new-post", "old-post"]
    end

    test "a date-only lteq excludes the rest of that day" do
      assert search_names(%{"category_inserted_at_lteq" => "2000-06-01"}) == []
      assert search_names(%{"category_inserted_at_lt" => "2000-06-02"}) == ["old-post"]
    end
  end
end
