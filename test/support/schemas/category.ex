defmodule EctoTurbo.Schemas.Category do
  @moduledoc false

  use Ecto.Schema

  @type t :: %__MODULE__{}

  schema "categories" do
    field(:name, :string)
    field(:posts_count, :integer)
    field(:status, Ecto.Enum, values: [draft: 0, published: 1], default: :draft)

    has_many(:posts, EctoTurbo.Schemas.Post)

    timestamps()
  end
end
