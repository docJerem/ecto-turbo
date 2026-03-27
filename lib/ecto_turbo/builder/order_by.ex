defmodule EctoTurbo.Builder.OrderBy do
  @moduledoc false

  import Ecto.Query

  alias EctoTurbo.Services.BuildSearchQuery

  @doc """
  Builds an order_by expression.
  """
  @spec build(Ecto.Queryable.t(), list(), list()) :: Ecto.Query.t()
  def build(query, sorts, binding) do
    binding_keys = extract_binding_keys(binding)

    order_exprs =
      Enum.map(sorts, fn %{direction: direction, attribute: %{name: name, parent: parent}} ->
        pos = Enum.find_index(binding_keys, &(&1 == parent)) || 0
        {direction, BuildSearchQuery.field_dynamic(pos, name)}
      end)

    order_by(query, ^order_exprs)
  end

  defp extract_binding_keys(binding) when is_list(binding) do
    Enum.map(binding, fn
      {name, _, _} -> name
      other -> other
    end)
  end
end
