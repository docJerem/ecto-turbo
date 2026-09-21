defmodule EctoTurbo.TestRepo.Migrations.AddStatusToCategories do
  use Ecto.Migration

  def change do
    alter table(:categories) do
      add :status, :integer, default: 0
    end
  end
end
