defmodule EctoTurbo.Config do
  @moduledoc false

  @doc false
  @spec per_page(atom()) :: integer()
  def per_page(application \\ :ecto_turbo) do
    config(:per_page, 10, application)
  end

  @doc false
  @spec repo(atom()) :: module() | nil
  def repo(application \\ :ecto_turbo) do
    config(:repo, nil, application)
  end

  @doc false
  @spec entry_name(atom()) :: String.t()
  def entry_name(application \\ :ecto_turbo) do
    config(:entry_name, "data", application)
  end

  @doc false
  @spec paginate_name(atom()) :: String.t()
  def paginate_name(application \\ :ecto_turbo) do
    config(:paginate_name, "paginate", application)
  end

  @doc false
  @spec defaults() :: keyword()
  def defaults do
    keys = ~w{repo per_page entry_name paginate_name}a
    Enum.map(keys, &get_defs/1)
  end

  defp get_defs(key) do
    {key, apply(__MODULE__, key, [])}
  end

  defp config(application) do
    Application.get_env(application, EctoTurbo, [])
  end

  defp config(key, default, application) do
    application
    |> config()
    |> Keyword.get(key, default)
    |> resolve_config(default)
  end

  defp resolve_config(value, _default), do: value
end
