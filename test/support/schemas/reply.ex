defmodule EctoTurbo.Schemas.Reply do
  @moduledoc false

  use Ecto.Schema

  @type t :: %__MODULE__{}

  schema "replies" do
    field(:content, :string)
    belongs_to(:post, EctoTurbo.Schemas.Post)

    timestamps()
  end
end
