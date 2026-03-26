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

  @doc """
  Builds a dynamic expression for the given search type, attribute and values.
  """
  @spec handle_expr(atom(), Attribute.t(), list(), [atom()]) :: Ecto.Query.dynamic_expr()
  def handle_expr(search_type, attribute, values, binding_keys \\ [:query])

  def handle_expr(:eq, attribute, [value | _], binding_keys) do
    f = field_dyn(attribute, binding_keys)
    dynamic(^f == ^value)
  end

  def handle_expr(:not_eq, attribute, [value | _], binding_keys) do
    f = field_dyn(attribute, binding_keys)
    dynamic(^f != ^value)
  end

  def handle_expr(:lt, attribute, [value | _], binding_keys) do
    f = field_dyn(attribute, binding_keys)
    dynamic(^f < ^value)
  end

  def handle_expr(:lteq, attribute, [value | _], binding_keys) do
    f = field_dyn(attribute, binding_keys)
    dynamic(^f <= ^value)
  end

  def handle_expr(:gt, attribute, [value | _], binding_keys) do
    f = field_dyn(attribute, binding_keys)
    dynamic(^f > ^value)
  end

  def handle_expr(:gteq, attribute, [value | _], binding_keys) do
    f = field_dyn(attribute, binding_keys)
    dynamic(^f >= ^value)
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
    dynamic(^f in ^values)
  end

  def handle_expr(:not_in, attribute, values, binding_keys) do
    f = field_dyn(attribute, binding_keys)
    dynamic(^f not in ^values)
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
    tl_val = hd(last)
    dynamic(^hd_val < ^f and ^f < ^tl_val)
  end

  def handle_expr(:between, attribute, [value | _], binding_keys) when is_binary(value) do
    result = value |> String.split("..") |> Enum.map(&maybe_to_number/1)
    handle_expr(:between, attribute, result, binding_keys)
  end

  defp maybe_to_number(str) when is_binary(str) do
    case Float.parse(str) do
      {num, ""} -> num
      _ -> str
    end
  end

  defp maybe_to_number(val), do: val

  # Resolves an attribute to a dynamic field expression at the correct binding position
  defp field_dyn(%Attribute{name: name, parent: parent}, binding_keys) do
    pos = Enum.find_index(binding_keys, &(&1 == parent)) || 0
    field_dynamic(pos, name)
  end
end
