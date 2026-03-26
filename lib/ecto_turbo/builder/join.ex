defmodule EctoTurbo.Builder.Join do
  @moduledoc false

  import Ecto.Query

  @doc """
  Builds a join expression.

  ## Example

      iex> query = EctoTurbo.Schemas.Post
      iex> relations = [:category, :repleis]
      iex> EctoTurbo.Builder.Join.build(query, relations)
      #Ecto.Query<from p0 in EctoTurbo.Schemas.Post, join: c1 in assoc(p0, :category), join: r2 in assoc(p0, :repleis)>

  """
  @spec build(Ecto.Queryable.t(), [atom()]) :: Ecto.Queryable.t()
  def build(query, relations) do
    Enum.reduce(relations, query, &apply_join(&1, &2))
  end

  @spec apply_join(atom(), Ecto.Queryable.t()) :: Ecto.Query.t()
  def apply_join(relation, query) do
    join(query, :inner, [q], x in assoc(q, ^relation))
  end
end
