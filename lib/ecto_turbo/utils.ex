defmodule EctoTurbo.Utils do
  @moduledoc """
  Utils functions.
  """

  @doc false
  @spec done(any()) :: {:ok, any()} | {:error, any()}
  def done({:error, reason}), do: {:error, reason}
  def done(result), do: {:ok, result}

  @doc """
  Converts all (string) map keys to atoms

  ## Examples

      iex> map = %{"a" => 1, "b" => %{"c" => 3, "d" => 4}}
      iex> EctoTurbo.Utils.symbolize_keys(map)
      %{a: 1, b: %{c: 3, d: 4}}

  """
  @spec symbolize_keys(map()) :: map()
  def symbolize_keys(map) do
    Enum.reduce(map, %{}, fn {k, v}, m ->
      v =
        case is_map(v) do
          true -> symbolize_keys(v)
          false -> v
        end

      map_atom_put(m, k, v)
    end)
  end

  defp map_atom_put(m, "data", v), do: Map.put(m, :data, v)
  defp map_atom_put(m, "pagination", v), do: Map.put(m, :pagination, v)

  defp map_atom_put(m, k, v) do
    if is_binary(k), do: Map.put(m, String.to_existing_atom(k), v), else: Map.put(m, k, v)
  end

  @doc """
  Converts all (atoms) map keys to string.

  ## Example

      iex> map = %{a: 1, b: %{c: 3, d: 4}}
      iex> EctoTurbo.Utils.stringify_keys(map)
      %{"a" => 1, "b" => %{"c" => 3, "d" => 4}}

      iex> EctoTurbo.Utils.stringify_keys(%{inserted_at: ~N[2024-01-01 00:00:00]})
      %{"inserted_at" => ~N[2024-01-01 00:00:00]}

  """
  @spec stringify_keys(any()) :: any()
  # A struct is a value, not a key/value container: pass it through untouched.
  def stringify_keys(%_{} = struct), do: struct

  def stringify_keys(map) when is_map(map) do
    Enum.into(map, %{}, fn {k, v} -> {to_string(k), stringify_keys(v)} end)
  end

  def stringify_keys(list) when is_list(list) do
    Enum.map(list, &stringify_keys/1)
  end

  def stringify_keys(not_a_map) do
    not_a_map
  end

  @doc """
  At the map object or list object, delete the key with Value is_nil or == "",
  and recursion is also considered.

  ## Examples

      iex> EctoTurbo.Utils.compaction!(%{nil_nil: nil, not_nil: "a value", nested: %{nil_val: nil, other: "other"}})
      %{not_nil: "a value", nested: %{other: "other"}}

      iex> EctoTurbo.Utils.compaction!(%{nil_nil: nil, not_nil: "a value", nested: %{nil_val: nil, other: "other", nested_empty: %{}}})
      %{not_nil: "a value", nested: %{other: "other"}}

      iex> EctoTurbo.Utils.compaction!([nil, "string", %{nil_nil: nil, not_nil: "a value", nested: %{nil_val: nil, other: "other", nested_empty: %{}}}, ["nested", nil, 2]])
      ["string", %{not_nil: "a value", nested: %{other: "other"}}, ["nested", 2]]

      iex> EctoTurbo.Utils.compaction!(%{inserted_at: ~N[2024-01-01 00:00:00], nil_val: nil})
      %{inserted_at: ~N[2024-01-01 00:00:00]}

  """
  @spec compaction!(map() | list()) :: map() | list()
  def compaction!(value)

  # Same as `stringify_keys/1`: a struct is a leaf value, never recursed into.
  def compaction!(%_{} = value), do: value

  def compaction!(value) when is_map(value) do
    compactor = fn {k, v}, acc ->
      cond do
        is_struct(v) -> Map.put_new(acc, k, v)
        is_map(v) and Enum.empty?(v) -> acc
        is_map(v) or is_list(v) -> Map.put_new(acc, k, compaction!(v))
        true -> Map.put_new(acc, k, v)
      end
    end

    value
    |> Enum.reduce(%{}, compactor)
    |> compactify!
  end

  def compaction!(value) when is_list(value) do
    compactor = fn elem, acc ->
      cond do
        is_struct(elem) -> acc ++ [elem]
        is_list(elem) and Enum.empty?(elem) -> acc
        is_list(elem) or is_map(elem) -> acc ++ [compaction!(elem)]
        is_nil(elem) -> acc
        true -> acc ++ [elem]
      end
    end

    value
    |> Enum.reduce([], compactor)
    |> compactify!
  end

  @doc """
  Takes a map or list and removes keys or elements that have nil or empty
  values, or are empty maps.

  ## Examples

      iex> EctoTurbo.Utils.compactify!(%{nil_key: nil, not_nil: "nil"})
      %{not_nil: "nil"}

      iex> EctoTurbo.Utils.compactify!([1, nil, "string", %{key: :value}])
      [1, "string", %{key: :value}]

      iex> EctoTurbo.Utils.compactify!([a: nil, b: 2, c: "string"])
      [b: 2, c: "string"]

      iex> EctoTurbo.Utils.compactify!(%{empty: %{}, not: "not"})
      %{not: "not"}

      iex> EctoTurbo.Utils.compactify!({"not", "a map"})
      ** (ArgumentError) expecting a map or a list, got: {"not", "a map"}

  """
  def compactify!(map) when is_map(map) do
    map
    |> Enum.reject(fn {_k, v} -> is_nil(v) || empty_string?(v) || empty_map?(v) end)
    |> Enum.into(%{})
  end

  def compactify!(list) when is_list(list) do
    list
    |> Keyword.keyword?()
    |> compactify!(list)
  end

  def compactify!(not_map_or_list),
    do:
      raise(ArgumentError, message: "expecting a map or a list, got: #{inspect(not_map_or_list)}")

  @doc false
  @spec compactify!(boolean(), list()) :: list()
  def compactify!(true, list), do: Enum.reject(list, fn {_k, v} -> is_nil(v) end)

  def compactify!(false, list), do: Enum.reject(list, fn elem -> is_nil(elem) end)

  defp empty_map?(map),
    do: is_map(map) && not Map.has_key?(map, :__struct__) && Enum.empty?(map)

  defp empty_string?(s), do: s == ""
end
