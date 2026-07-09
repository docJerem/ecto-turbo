defmodule EctoTurbo.Hooks.Search.Attribute do
  @moduledoc """
  Search Attribute.
  """

  alias EctoTurbo.Hooks.Search.Attribute

  # `type` holds the resolved schema type when the field's values need coercion
  # before hitting the database (currently `Ecto.Enum`). It stays `nil` for
  # plain fields whose query params can be passed through as-is, and is hidden
  # from `Inspect` so it doesn't leak into unrelated output.
  @derive {Inspect, optional: [:type]}
  defstruct name: nil, parent: nil, type: nil

  @type t :: %__MODULE__{}

  @doc """
  Extract Attribute.

  ## TODO

    * Support multi table assoc, limit: 5.

  """
  @spec extract(String.t(), module()) :: t() | {:error, atom()}
  def extract(key, module) do
    case get_name(module, key) || get_assoc_name(module, key) do
      nil -> {:error, :attribute_not_found}
      {_assoc, nil} -> {:error, :attribute_not_found}
      {assoc, name} -> %Attribute{parent: assoc, name: name, type: assoc_type(module, assoc, name)}
      name -> %Attribute{parent: :query, name: name, type: coercible_type(module, name)}
    end
  end

  defp assoc_type(module, assoc, name) do
    case module.__schema__(:association, assoc) do
      %{related: related} -> coercible_type(related, name)
      _ -> nil
    end
  end

  # Only surface types whose values need coercion before query time. Enums are
  # stored under a different representation (e.g. integers), so the string params
  # must be cast + dumped or the database rejects them.
  defp coercible_type(module, name) do
    case module.__schema__(:type, name) do
      {:parameterized, {Ecto.Enum, _params}} = type -> type
      _ -> nil
    end
  end

  defp get_assoc_name(module, key) do
    case get_assoc(module, key) do
      nil ->
        nil

      assoc ->
        key = String.replace_prefix(key, "#{assoc}_", "")
        {assoc, get_name(module.__schema__(:association, assoc), key)}
    end
  end

  defp get_assoc(module, key) do
    :associations
    |> module.__schema__
    |> find_field(key)
  end

  defp get_name(%{related: module}, key) do
    get_name(module, key)
  end

  defp get_name(module, key) do
    :fields
    |> module.__schema__
    |> find_field(key)
  end

  defp find_field(fields, key) do
    fields
    |> Enum.sort_by(&String.length(to_string(&1)), &>=/2)
    |> Enum.find(&String.starts_with?(key, to_string(&1)))
  end
end
