defmodule EctoTurbo.Hooks.Paginate do
  @moduledoc false

  import Ecto.Query
  alias EctoTurbo.Config, as: TConfig
  alias EctoTurbo.Hooks.Paginate

  defstruct [:limit, :offset]

  @type t :: %__MODULE__{}
  @per_page TConfig.per_page()

  @doc """
  Returns paginate object.

  ## Example

      iex> params = %{"per_page" => 5, "page" => 2}
      iex> EctoTurbo.Hooks.Paginate.run(params)
      {:ok, %EctoTurbo.Hooks.Paginate{limit: 5, offset: 5}}

      iex> params = %{}
      iex> EctoTurbo.Hooks.Paginate.run(params)
      {:ok, %EctoTurbo.Hooks.Paginate{limit: 10, offset: 0}}

  """
  @spec run(map()) :: {:ok, t()}
  def run(params) do
    params
    |> format_params()
    |> handle_paginate()
  end

  defp format_params(params) do
    params
    |> Map.put_new(:per_page, format_integer(Map.get(params, "per_page", @per_page)))
    |> Map.put_new(:page, format_integer(Map.get(params, "page", 1)))
  end

  # build queryable
  defp handle_paginate(formated_params) do
    per_page = Map.get(formated_params, :per_page)
    page = Map.get(formated_params, :page)

    offset = per_page * (page - 1)

    {:ok, %Paginate{limit: per_page, offset: offset}}
  end

  # format date, replace string to integer
  defp format_integer(value) do
    if is_integer(value), do: value, else: String.to_integer(value)
  end

  @doc """
  Returns the paginate info.
  """
  @spec get_paginate(Ecto.Query.t(), map(), Keyword.t()) :: map()
  def get_paginate(queryable, params, opts) do
    formated_params = format_params(params)

    case Keyword.get(opts, :repo) do
      nil -> raise "Expected key `repo` in `opts`, got #{inspect(opts)}"
      repo -> do_get_paginate(queryable, formated_params, repo)
    end
  end

  @doc false
  @spec do_get_paginate(Ecto.Query.t(), map(), module()) :: map()
  def do_get_paginate(queryable, formated_params, repo) do
    per_page = Map.get(formated_params, :per_page)
    total_count = get_total_count(queryable, repo)

    total_pages =
      total_count
      |> (&(&1 / per_page)).()
      |> Float.ceil()
      |> trunc()

    current_page = Map.get(formated_params, :page)
    next_page = if total_pages - current_page >= 1, do: current_page + 1, else: nil

    prev_page =
      if total_pages >= current_page && current_page > 1, do: current_page - 1, else: nil

    %{
      current_page: current_page,
      current_pages: current_pages(current_page, total_pages),
      per_page: per_page,
      total_count: total_count,
      total_pages: total_pages,
      next_page: next_page,
      prev_page: prev_page
    }
  end

  @doc """
  Computes a rendered list of page numbers with `"..."` ellipsis markers
  for display in pagination controls.

  Limits to a max of 9 visible pages with ellipsis to synthesize the pagination.

  Returns `[1]` when there are no pages or `total_pages` is not positive.

  ## Example

      iex> EctoTurbo.Hooks.Paginate.current_pages(463, 5002)
      [1, "...", 461, 462, 463, 464, 465, "...", 5002]

  """
  @spec current_pages(integer(), integer()) :: [integer() | String.t()]
  def current_pages(_current_page, total_pages) when total_pages <= 0, do: [1]

  def current_pages(current_page, total_pages) do
    current_page = ensure_current_page(current_page, total_pages)

    create_center_from(current_page)
    |> filter_center(total_pages)
    |> include_tree_left(current_page)
    |> include_tree_right(current_page, total_pages)
    |> include_left_dots(current_page)
    |> include_right_dots(current_page, total_pages)
    |> merge_parts(total_pages)
    |> handle_one_page()
  end

  defp ensure_current_page(current, total_pages) do
    cond do
      current < 1 -> 1
      current > total_pages -> total_pages
      true -> current
    end
  end

  defp create_center_from(current),
    do: [current - 2, current - 1, current, current + 1, current + 2]

  defp filter_center(center, total) do
    Enum.filter(center, fn p -> p > 1 && p < total end)
  end

  defp include_tree_left(filtered_center, current) when current == 5 do
    [2] ++ filtered_center
  end

  defp include_tree_left(filtered_center, _), do: filtered_center

  defp include_tree_right(filtered_center, current, total) when current == total - 4 do
    filtered_center ++ [total - 1]
  end

  defp include_tree_right(filtered_center, _, _), do: filtered_center

  defp include_left_dots(filtered_center, current) when current > 5 do
    ["..."] ++ filtered_center
  end

  defp include_left_dots(filtered_center, _), do: filtered_center

  defp include_right_dots(filtered_center, current, total) when current < total - 4 do
    filtered_center ++ ["..."]
  end

  defp include_right_dots(filtered_center, _, _), do: filtered_center

  defp merge_parts(filtered_center, total), do: [1] ++ filtered_center ++ [total]

  defp handle_one_page([1, 0]), do: [1]
  defp handle_one_page([1, 1]), do: [1]
  defp handle_one_page(result), do: result

  defp get_total_count(queryable, repo) do
    queryable
    |> exclude(:select)
    |> exclude(:preload)
    |> exclude(:order_by)
    |> exclude(:limit)
    |> exclude(:offset)
    |> get_count(repo)
  end

  defp get_count(query, repo) do
    repo.aggregate(query, :count, :id)
  end
end
