defmodule EctoTurbo.Services.BuildSearchQuery do
  @moduledoc """
  `EctoTurbo.Services.BuildSearchQuery` is a service module which serves the search hook.

  `@search_types` is a collection of all the valid `search_types` that come shipped with
  `EctoTurbo`'s default search hook. The types are:

  * [x] `eq`: equal. (SQL: `col = 'value'`)
  * [x] `not_eq`: not equal. (SQL: col != 'value')
  * [x] `lt`: less than. (SQL: col < 1024)
  * [x] `lteq`: less than or equal. (SQL: col <= 1024)
  * [x] `gt`: greater than. (SQL: col > 1024)
  * [x] `gteq`: greater than or equal. (SQL: col >= 1024)
  * [x] `is_present`: not null and not empty. (SQL: col is not null AND col != '')
  * [x] `is_blank`: is null or empty. (SQL: col is null OR col = '')
  * [x] `is_null`: is null or not null (SQL: col is null)
  * [x] `is_true` is true. (SQL: col is true)
  * [x] `is_not_true` is not true. (SQL: col is false)
  * [x] `is_false` is false. (SQL: col is false)
  * [x] `is_not_false` is true. (SQL: col is true)
  * [x] `like`: contains trem value. (SQL: col like "%value%")
  * [x] `not_like`: not contains value. (SQL: col not like '%value%')
  * [x] `ilike`: contains value in a case insensitive fashion. (SQL: )
  * [x] `not_ilike`: not contains value in a case insensitive fashion. (SQL:
  * [x] `in` contains. (SQL: col in ['1024', '1025'])
  * [x] `not_in` not contains. (SQL: col not in ['1024', '1025'])
  * [x] `start_with` start with. (SQL: col like 'value%')
  * [x] `not_start_with` not start with. (SQL: col not like 'value%')
  * [x] `end_with` end with. (SQL: col like '%value')
  * [x] `not_end_with` (SQL: col not like '%value')
  * [x] `between`: between begin and end. (SQL: begin <= col and col <= end)
  """

  import Ecto.Query

  alias EctoTurbo.Hooks.Search.Attribute

  @search_types ~w(eq
                  not_eq
                  lt
                  lteq
                  gt
                  gteq
                  is_true
                  is_not_true
                  is_false
                  is_not_false
                  is_present
                  is_blank
                  is_null
                  is_not_null
                  like
                  not_like
                  ilike
                  not_ilike
                  in
                  not_in
                  start_with
                  not_start_with
                  end_with
                  not_end_with
                  between
                  )

  @true_values [1, ~c"1", ~c"T", ~c"t", true, ~c"true", ~c"TRUE", "1", "T", "t", "true", "TRUE"]
  @false_values [
    0,
    ~c"0",
    ~c"F",
    ~c"f",
    false,
    ~c"false",
    ~c"FALSE",
    "0",
    "F",
    "f",
    "false",
    "FALSE"
  ]

  @doc false
  @spec search_types() :: [String.t()]
  def search_types, do: @search_types

  # Search types whose values are compared against the column value and must
  # therefore be in the column's stored representation. Pattern (`like`, ...)
  # and predicate (`is_null`, `is_true`, ...) search types are left untouched.
  @coercible_search_types ~w(eq not_eq lt lteq gt gteq in not_in between)a

  @doc """
  Coerces the search values to the representation expected by the database for
  the given attribute and search type.

  Every compared value is typed against its column in `handle_expr/4`, so Ecto
  casts and dumps it through the adapter like it would for `q.field == ^value`.
  This function only handles what Ecto cannot do on its own: a clear
  `ArgumentError` at build time (instead of an `Ecto.Query.CastError` at query
  time) for `Ecto.Enum` and date/time columns, the `begin..end` between form,
  and a date-only value (`"2024-01-01"` or a `Date`) against a datetime column,
  which is taken as midnight. Attributes without such a type, and search types
  that do not compare the column against a value, pass their values through
  untouched.
  """
  @spec coerce_values(atom(), Attribute.t(), list()) :: list()
  def coerce_values(_search_type, %Attribute{type: nil}, values), do: values

  def coerce_values(:between, %Attribute{} = attribute, [value]) when is_binary(value),
    do: coerce_values(:between, attribute, String.split(value, ".."))

  def coerce_values(search_type, %Attribute{type: type} = attribute, values)
      when search_type in @coercible_search_types,
      do: Enum.map(values, &coerce_value(type, attribute, &1))

  def coerce_values(_search_type, %Attribute{}, values), do: values

  defp coerce_value(type, attribute, value) do
    case cast(type, value) do
      {:ok, cast} ->
        cast

      # `Ecto.Type.cast/2` returns a bare `:error` or, for parameterized
      # types such as `Ecto.Enum`, `{:error, keyword}`.
      _ ->
        raise ArgumentError,
              "invalid search value #{inspect(value)} for attribute #{inspect(attribute.name)}, " <>
                expected(type)
    end
  end

  @datetime_types ~w(naive_datetime naive_datetime_usec utc_datetime utc_datetime_usec)a

  # A date-only value against a datetime column falls back to that date at midnight.
  defp cast(type, value) when type in @datetime_types do
    with :error <- Ecto.Type.cast(type, value),
         {:ok, date} <- Ecto.Type.cast(:date, value) do
      Ecto.Type.cast(type, NaiveDateTime.new!(date, ~T[00:00:00]))
    else
      {:ok, _} = ok -> ok
      _ -> :error
    end
  end

  defp cast(type, value), do: Ecto.Type.cast(type, value)

  defp expected({:parameterized, {Ecto.Enum, params}}), do: expected_enum(params)
  defp expected({:parameterized, Ecto.Enum, params}), do: expected_enum(params)
  defp expected(type), do: "expected a value of type #{inspect(type)}"

  defp expected_enum(%{mappings: mappings}),
    do: "expected one of #{inspect(Keyword.keys(mappings))}"

  # Generate field_dynamic/2 helpers for binding positions 0-5.
  # Position 0 is the main query, 1+ are joins.
  @doc false
  @spec field_dynamic(non_neg_integer(), atom()) :: Ecto.Query.dynamic_expr()
  def field_dynamic(0, name), do: dynamic([q], field(q, ^name))
  def field_dynamic(1, name), do: dynamic([_, b1], field(b1, ^name))
  def field_dynamic(2, name), do: dynamic([_, _, b2], field(b2, ^name))
  def field_dynamic(3, name), do: dynamic([_, _, _, b3], field(b3, ^name))
  def field_dynamic(4, name), do: dynamic([_, _, _, _, b4], field(b4, ^name))
  def field_dynamic(5, name), do: dynamic([_, _, _, _, _, b5], field(b5, ^name))

  # A field built through `field_dynamic/2` is opaque once interpolated, so
  # `dynamic(^f == ^value)` gives Ecto no way to know which column `value` is
  # compared to and the raw Elixir term reaches the adapter (a UUID string on a
  # `:binary_id`, an ISO string on a timestamp, ...). Typing the value against
  # the field restores the cast + adapter dump Ecto performs for `q.f == ^value`.
  @doc false
  @spec typed_value_dynamic(non_neg_integer(), atom(), term()) :: Ecto.Query.dynamic_expr()
  def typed_value_dynamic(0, name, v), do: dynamic([q], type(^v, field(q, ^name)))
  def typed_value_dynamic(1, name, v), do: dynamic([_, b1], type(^v, field(b1, ^name)))
  def typed_value_dynamic(2, name, v), do: dynamic([_, _, b2], type(^v, field(b2, ^name)))
  def typed_value_dynamic(3, name, v), do: dynamic([_, _, _, b3], type(^v, field(b3, ^name)))
  def typed_value_dynamic(4, name, v), do: dynamic([_, _, _, _, b4], type(^v, field(b4, ^name)))

  def typed_value_dynamic(5, name, v),
    do: dynamic([_, _, _, _, _, b5], type(^v, field(b5, ^name)))

  @doc false
  @spec typed_values_dynamic(non_neg_integer(), atom(), list()) :: Ecto.Query.dynamic_expr()
  def typed_values_dynamic(0, name, vs), do: dynamic([q], type(^vs, {:array, field(q, ^name)}))

  def typed_values_dynamic(1, name, vs),
    do: dynamic([_, b1], type(^vs, {:array, field(b1, ^name)}))

  def typed_values_dynamic(2, name, vs),
    do: dynamic([_, _, b2], type(^vs, {:array, field(b2, ^name)}))

  def typed_values_dynamic(3, name, vs),
    do: dynamic([_, _, _, b3], type(^vs, {:array, field(b3, ^name)}))

  def typed_values_dynamic(4, name, vs),
    do: dynamic([_, _, _, _, b4], type(^vs, {:array, field(b4, ^name)}))

  def typed_values_dynamic(5, name, vs),
    do: dynamic([_, _, _, _, _, b5], type(^vs, {:array, field(b5, ^name)}))

  @doc """
  Builds a dynamic expression for the given search type, attribute and values.
  """
  @spec handle_expr(atom(), Attribute.t(), list(), [atom()]) :: Ecto.Query.dynamic_expr()
  def handle_expr(search_type, attribute, values, binding_keys \\ [:query])

  def handle_expr(:eq, attribute, [value | _], binding_keys) do
    f = field_dyn(attribute, binding_keys)
    v = typed_value_dyn(attribute, value, binding_keys)
    dynamic(^f == ^v)
  end

  def handle_expr(:not_eq, attribute, [value | _], binding_keys) do
    f = field_dyn(attribute, binding_keys)
    v = typed_value_dyn(attribute, value, binding_keys)
    dynamic(^f != ^v)
  end

  def handle_expr(:lt, attribute, [value | _], binding_keys) do
    f = field_dyn(attribute, binding_keys)
    v = typed_value_dyn(attribute, value, binding_keys)
    dynamic(^f < ^v)
  end

  def handle_expr(:lteq, attribute, [value | _], binding_keys) do
    f = field_dyn(attribute, binding_keys)
    v = typed_value_dyn(attribute, value, binding_keys)
    dynamic(^f <= ^v)
  end

  def handle_expr(:gt, attribute, [value | _], binding_keys) do
    f = field_dyn(attribute, binding_keys)
    v = typed_value_dyn(attribute, value, binding_keys)
    dynamic(^f > ^v)
  end

  def handle_expr(:gteq, attribute, [value | _], binding_keys) do
    f = field_dyn(attribute, binding_keys)
    v = typed_value_dyn(attribute, value, binding_keys)
    dynamic(^f >= ^v)
  end

  def handle_expr(:like, attribute, [value | _], binding_keys) do
    f = field_dyn(attribute, binding_keys)
    pattern = "%#{value}%"
    dynamic(like(^f, ^pattern))
  end

  def handle_expr(:not_like, attribute, [value | _], binding_keys) do
    f = field_dyn(attribute, binding_keys)
    pattern = "%#{value}%"
    dynamic(not like(^f, ^pattern))
  end

  def handle_expr(:ilike, attribute, [value | _], binding_keys) do
    f = field_dyn(attribute, binding_keys)
    pattern = "%#{value}%"
    dynamic(ilike(^f, ^pattern))
  end

  def handle_expr(:not_ilike, attribute, [value | _], binding_keys) do
    f = field_dyn(attribute, binding_keys)
    pattern = "%#{value}%"
    dynamic(not ilike(^f, ^pattern))
  end

  def handle_expr(:in, attribute, values, binding_keys) do
    f = field_dyn(attribute, binding_keys)
    v = typed_values_dyn(attribute, values, binding_keys)
    dynamic(^f in ^v)
  end

  def handle_expr(:not_in, attribute, values, binding_keys) do
    f = field_dyn(attribute, binding_keys)
    v = typed_values_dyn(attribute, values, binding_keys)
    dynamic(^f not in ^v)
  end

  def handle_expr(:start_with, attribute, [value | _], binding_keys) do
    f = field_dyn(attribute, binding_keys)
    pattern = "#{value}%"
    dynamic(ilike(^f, ^pattern))
  end

  def handle_expr(:not_start_with, attribute, [value | _], binding_keys) do
    f = field_dyn(attribute, binding_keys)
    pattern = "#{value}%"
    dynamic(not ilike(^f, ^pattern))
  end

  def handle_expr(:end_with, attribute, [value | _], binding_keys) do
    f = field_dyn(attribute, binding_keys)
    pattern = "%#{value}"
    dynamic(ilike(^f, ^pattern))
  end

  def handle_expr(:not_end_with, attribute, [value | _], binding_keys) do
    f = field_dyn(attribute, binding_keys)
    pattern = "%#{value}"
    dynamic(not ilike(^f, ^pattern))
  end

  def handle_expr(:is_true, attribute, [value | _], binding_keys) when value in @true_values do
    handle_expr(:eq, attribute, [true], binding_keys)
  end

  def handle_expr(:is_true, attribute, [value | _], binding_keys) when value in @false_values do
    handle_expr(:not_eq, attribute, [true], binding_keys)
  end

  def handle_expr(:is_not_true, attribute, [value | _], binding_keys)
      when value in @true_values do
    handle_expr(:eq, attribute, [false], binding_keys)
  end

  def handle_expr(:is_not_true, attribute, [value | _], binding_keys)
      when value in @false_values do
    handle_expr(:not_eq, attribute, [false], binding_keys)
  end

  def handle_expr(:is_false, attribute, [value | _], binding_keys) when value in @true_values do
    handle_expr(:eq, attribute, [false], binding_keys)
  end

  def handle_expr(:is_false, attribute, [value | _], binding_keys) when value in @false_values do
    handle_expr(:not_eq, attribute, [false], binding_keys)
  end

  def handle_expr(:is_not_false, attribute, [value | _], binding_keys)
      when value in @true_values do
    handle_expr(:not_eq, attribute, [false], binding_keys)
  end

  def handle_expr(:is_not_false, attribute, [value | _], binding_keys)
      when value in @false_values do
    handle_expr(:eq, attribute, [false], binding_keys)
  end

  def handle_expr(:is_null, attribute, [value | _], binding_keys) when value in @true_values do
    f = field_dyn(attribute, binding_keys)
    dynamic(is_nil(^f))
  end

  def handle_expr(:is_null, attribute, [value | _], binding_keys) when value in @false_values do
    f = field_dyn(attribute, binding_keys)
    dynamic(not is_nil(^f))
  end

  def handle_expr(:is_not_null, attribute, [value | _] = values, binding_keys)
      when value in @true_values do
    is_null_dyn = handle_expr(:is_null, attribute, values, binding_keys)
    dynamic(not (^is_null_dyn))
  end

  def handle_expr(:is_not_null, attribute, [value | _] = values, binding_keys)
      when value in @false_values do
    handle_expr(:is_null, attribute, values, binding_keys)
  end

  def handle_expr(:is_blank, attribute, [value | _], binding_keys) when value in @true_values do
    f = field_dyn(attribute, binding_keys)
    dynamic(is_nil(^f) or ^f == ^"")
  end

  def handle_expr(:is_blank, attribute, [value | _], binding_keys) when value in @false_values do
    f = field_dyn(attribute, binding_keys)
    dynamic(not is_nil(^f) or ^f != ^"")
  end

  def handle_expr(:is_present, attribute, [value | _] = values, binding_keys)
      when value in @true_values do
    blank_dyn = handle_expr(:is_blank, attribute, values, binding_keys)
    dynamic(not (^blank_dyn))
  end

  def handle_expr(:is_present, attribute, [value | _] = values, binding_keys)
      when value in @false_values do
    handle_expr(:is_blank, attribute, values, binding_keys)
  end

  def handle_expr(:matches, attribute, [value | _], binding_keys) do
    f = field_dyn(attribute, binding_keys)
    dynamic(ilike(^f, ^value))
  end

  def handle_expr(:does_not_match, attribute, [value | _], binding_keys) do
    f = field_dyn(attribute, binding_keys)
    dynamic(not ilike(^f, ^value))
  end

  def handle_expr(:between, attribute, [hd_val | last] = values, binding_keys)
      when length(values) == 2 do
    f = field_dyn(attribute, binding_keys)
    lo = typed_value_dyn(attribute, hd_val, binding_keys)
    hi = typed_value_dyn(attribute, hd(last), binding_keys)
    dynamic(^lo < ^f and ^f < ^hi)
  end

  # The bounds stay strings: they are typed against the column, so Ecto casts
  # them to its actual type (an integer column would reject a parsed float).
  def handle_expr(:between, attribute, [value | _], binding_keys) when is_binary(value) do
    handle_expr(:between, attribute, String.split(value, ".."), binding_keys)
  end

  # Resolves an attribute to a dynamic field expression at the correct binding position
  defp field_dyn(%Attribute{name: name} = attribute, binding_keys),
    do: field_dynamic(binding_pos(attribute, binding_keys), name)

  defp typed_value_dyn(%Attribute{name: name} = attribute, value, binding_keys),
    do: typed_value_dynamic(binding_pos(attribute, binding_keys), name, value)

  defp typed_values_dyn(%Attribute{name: name} = attribute, values, binding_keys),
    do: typed_values_dynamic(binding_pos(attribute, binding_keys), name, values)

  defp binding_pos(%Attribute{parent: parent}, binding_keys),
    do: Enum.find_index(binding_keys, &(&1 == parent)) || 0
end
