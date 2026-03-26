defmodule EctoTurbo.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/cryptr-auth/ecto_turbo"

  def project do
    [
      app: :ecto_turbo,
      version: @version,
      elixirc_options: [
        warnings_as_errors: true
      ],
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      docs: docs(),
      package: package(),
      name: "EctoTurbo",
      description: "A rich Ecto component for searching, sorting, and paginating queries.",
      source_url: @source_url
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ecto_sql, "~> 3.11"},
      {:postgrex, "~> 0.19", only: :test},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:ex_machina, "~> 2.8", only: :test}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "priv", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      test: [
        "ecto.drop -r EctoTurbo.TestRepo --quiet",
        "ecto.create -r EctoTurbo.TestRepo --quiet",
        "ecto.migrate -r EctoTurbo.TestRepo --quiet",
        "test"
      ]
    ]
  end

  defp docs do
    [
      extras: [
        "CHANGELOG.md": [],
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      source_url: @source_url,
      formatters: ["html"]
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE.md", "CHANGELOG.md"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end
end
