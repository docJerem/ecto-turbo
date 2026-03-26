defmodule EctoTurbo.Builder.LimitOffset do
  @moduledoc false

  import Ecto.Query

  @doc """
  Builds a limit or offset expression.

  ## Examples

  When type is `:limit`:
      iex> type = :limit
      iex> query = EctoTurbo.Schemas.Post
      iex> val = 1
      iex> EctoTurbo.Builder.LimitOffset.build(type, query, val, [])
      #Ecto.Query<from p0 in EctoTurbo.Schemas.Post, limit: ^1>

  When type is `:offset`:
      iex> type = :offset
      iex> query = EctoTurbo.Schemas.Post
      iex> val = 1
      iex> EctoTurbo.Builder.LimitOffset.build(type, query, val, [])
      #Ecto.Query<from p0 in EctoTurbo.Schemas.Post, offset: ^1>

  """
  @spec build(:limit | :offset, Ecto.Queryable.t(), integer(), term()) :: Ecto.Query.t()
  def build(:limit, query, val, _binding) do
    limit(query, ^val)
  end

  def build(:offset, query, val, _binding) do
    offset(query, ^val)
  end
end
