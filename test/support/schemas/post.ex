defmodule EctoTurbo.Schemas.Post do
  @moduledoc false

  use Ecto.Schema

  @type t :: %__MODULE__{}

  schema "posts" do
    field(:name, :string)
    field(:body, :string)
    field(:price, :float)
    field(:available, :boolean)
    field(:replies_count, :integer)

    belongs_to(:category, EctoTurbo.Schemas.Category)
    has_many(:replies, EctoTurbo.Schemas.Reply)

    timestamps()
  end
end
