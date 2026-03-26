defmodule EctoTurbo.Hooks.Sort do
  @moduledoc false

  alias EctoTurbo.Hooks.Sort
  alias EctoTurbo.Hooks.Search.Attribute

  defstruct attribute: nil, direction: nil

  @atom :datas
  @type t :: %__MODULE__{}
  @sort_order ~w(asc desc)

  @doc """
  Returns sort object.

  ## Examples

  When sort with one field:

      iex> params = %{}
      iex> EctoTurbo.Hooks.Sort.run(EctoTurbo.Schemas.Post, params)
      {:ok,[]}

      iex> params = %{"s" => "inserted_at+desc"}
      iex> EctoTurbo.Hooks.Sort.run(EctoTurbo.Schemas.Post, params)
      {:ok,
        [
          %EctoTurbo.Hooks.Sort{
            attribute: %EctoTurbo.Hooks.Search.Attribute{
              name: :inserted_at,
              parent: :query
            },
            direction: :desc
          }
        ]
      }

  When sort with multi fields:

      iex> params = %{"s" => ["updated_at+desc", "inserted_at+asc"]}
      iex> EctoTurbo.Hooks.Sort.run(EctoTurbo.Schemas.Post, params)
      {:ok,
        [
          %EctoTurbo.Hooks.Sort{
            attribute: %EctoTurbo.Hooks.Search.Attribute{
              name: :updated_at,
              parent: :query
            },
            direction: :desc
          },
          %EctoTurbo.Hooks.Sort{
            attribute: %EctoTurbo.Hooks.Search.Attribute{
              name: :inserted_at,
              parent: :query
            },
            direction: :asc
          }
        ]
      }

  """
  @spec run(Ecto.Query.t(), map()) :: tuple()
  def run(schema, params)

  def run(schema, %{"s" => s}) do
    s
    |> handle_sort(schema)
    |> result()
  end

  def run(schema, %{"sort" => sort}) do
    sort
    |> handle_sort(schema)
    |> result()
  end

  def run(schema, _) do
    []
    |> handle_sort(schema)
    |> result()
  end

  # Used to avoid crash due to missing atom
  def datas(), do: @atom

  defp handle_sort(value, schema) when is_binary(value) do
    value
    |> build(schema)
    |> List.wrap()
  end

  defp handle_sort(values, schema) do
    values
    |> Enum.map(&build(&1, schema))
  end

  defp build(value, schema) do
    value
    |> Attribute.extract(schema)
    |> result(parse_direction(value))
  end

  defp result(sorts) when is_list(sorts), do: {:ok, sorts}
  defp result(_attribute, nil), do: {:error, :direction_not_found}
  defp result({:error, reason}, _direction), do: {:error, reason}

  defp result(attribute, direction),
    do: %Sort{attribute: attribute, direction: String.to_existing_atom(direction)}

  defp parse_direction(value) do
    value
    |> String.split(~r/\+/)
    |> Enum.find(&Enum.member?(@sort_order, &1))
  end
end
