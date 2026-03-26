defmodule EctoTurbo.Builder.Where do
  @moduledoc false

  import Ecto.Query

  alias EctoTurbo.Hooks.Search
  alias EctoTurbo.Services.BuildSearchQuery
  alias Search.Condition

  @doc false
  @spec build(Ecto.Queryable.t(), Search.t(), term()) :: Ecto.Query.t()
  def build(query, %Search{combinator: combinator} = grouping, binding)
      when combinator in ~w(and or)a do
    binding_keys = extract_binding_keys(binding)
    dyn = grouping |> List.wrap() |> groupings_dynamic(binding_keys)
    where(query, ^dyn)
  end

  defp extract_binding_keys(binding) when is_list(binding) do
    Enum.map(binding, fn
      {name, _, _} -> name
      other -> other
    end)
  end

  defp grouping_dynamic(%Search{conditions: []}, binding_keys: _binding_keys) do
    dynamic(true)
  end

  defp grouping_dynamic(%Search{combinator: combinator, conditions: conditions},
         binding_keys: binding_keys
       ) do
    conditions
    |> Enum.map(&condition_dynamic(&1, binding_keys))
    |> combine_dynamics(combinator)
  end

  defp condition_dynamic(
         %Condition{
           attributes: attrs,
           values: vals,
           search_type: search_type,
           combinator: combinator
         },
         binding_keys
       ) do
    attrs
    |> Enum.map(&BuildSearchQuery.handle_expr(search_type, &1, vals, binding_keys))
    |> combine_dynamics(combinator)
  end

  defp groupings_dynamic(groupings, binding_keys),
    do: groupings_dynamic(groupings, binding_keys, [], nil)

  defp groupings_dynamic([%{groupings: []} = parent], binding_keys, [], nil),
    do: grouping_dynamic(parent, binding_keys: binding_keys)

  defp groupings_dynamic([%{groupings: []} = parent | tail], binding_keys, acc, combinator_acc) do
    groupings_dynamic(
      tail,
      binding_keys,
      acc ++ [grouping_dynamic(parent, binding_keys: binding_keys)],
      combinator_acc
    )
  end

  defp groupings_dynamic(
         [%{combinator: combinator, groupings: children} = parent | tail],
         binding_keys,
         acc,
         combinator_acc
       ) do
    children_exprs =
      groupings_dynamic(
        children,
        binding_keys,
        acc ++ [grouping_dynamic(parent, binding_keys: binding_keys)],
        combinator
      )

    groupings_dynamic(tail, binding_keys, children_exprs, combinator_acc)
  end

  defp groupings_dynamic([], _binding_keys, acc, nil), do: acc

  defp groupings_dynamic([], _binding_keys, acc, combinator),
    do: combine_dynamics(acc, combinator)

  defp combine_dynamics([], _combinator), do: dynamic(true)
  defp combine_dynamics([single], _combinator), do: single

  defp combine_dynamics([first | rest], :and) do
    Enum.reduce(rest, first, fn expr, acc ->
      dynamic(^acc and ^expr)
    end)
  end

  defp combine_dynamics([first | rest], :or) do
    Enum.reduce(rest, first, fn expr, acc ->
      dynamic(^acc or ^expr)
    end)
  end
end
