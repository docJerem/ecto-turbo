defmodule EctoTurbo.List do
  @moduledoc """
  Represents a paginated list response.

  Wraps query results with pagination metadata for consistent
  JSON serialization. EctoTurbo.turbo/3 returns this struct.

  The JSON keys for entries and pagination metadata can be customized
  via the `:entry_name` and `:paginate_name` options passed to `new/3`.

  ## Default JSON Output

      {
        "data": [...],
        "pagination": {
          "current_page": 1,
          "current_pages": [1],
          "per_page": 10,
          "next_page": 1,
          "prev_page": 1,
          "total_pages": 1
        },
        "total": 42
      }

  ## Custom keys

      EctoTurbo.List.new(items, paginate, entry_name: "users", paginate_name: "meta")
      # => {"data": [...], "pagination": {...}, "total": 42}

  """

  @type t :: %__MODULE__{
          data: list(),
          pagination: map(),
          total: non_neg_integer(),
          entry_name: String.t(),
          paginate_name: String.t()
        }

  defstruct __type__: "List",
            data: [],
            pagination: %{},
            total: 0,
            entry_name: "data",
            paginate_name: "pagination"

  @doc """
  Builds a List from raw query results and paginate metadata.

  ## Options

    - `:entry_name` — JSON key for the items list (default `"data"`)
    - `:paginate_name` — JSON key for the pagination map (default `"pagination"`)
  """
  @spec new(list(), map(), keyword()) :: t()
  def new(items, paginate, opts \\ []) when is_list(items) and is_map(paginate) do
    total_pages = paginate[:total_pages] || 0
    current_page = paginate[:current_page] || 1

    %__MODULE__{
      data: items,
      total: paginate[:total_count] || length(items),
      entry_name: Keyword.get(opts, :entry_name, "data"),
      paginate_name: Keyword.get(opts, :paginate_name, "pagination"),
      pagination: %{
        current_page: current_page,
        current_pages: paginate[:current_pages] || [1],
        per_page: paginate[:per_page] || Keyword.get(opts, :default_per_page, 10),
        total_pages: total_pages,
        next_page: paginate[:next_page] || total_pages,
        prev_page: paginate[:prev_page] || 1
      }
    }
  end

  defimpl Jason.Encoder do
    def encode(list, opts) do
      %{
        list.entry_name => list.data,
        list.paginate_name => list.pagination,
        "total" => list.total
      }
      |> Jason.Encode.map(opts)
    end
  end
end
