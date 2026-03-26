defmodule EctoTurbo.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/docjerem/ecto-turbo"

  def project do
    [
      app: :ecto_turbo,
      version: @version,
      elixirc_options: [
        warnings_as_errors: true
      ],
      elixir: "~> 1.17",
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
      {:ex_machina, "~> 2.8", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:doctor, "~> 0.22", only: :dev, runtime: false},
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "priv", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      audit: [
        "credo --strict",
        "deps.audit",
        "deps.unlock --check-unused",
        "dialyzer --format github",
        "doctor --raise",
        "format --check-formatted",
        "sobelow --config",
        # Hex tasks do not work in aliases, so we shell out:
        &run_hex_outdated/1,
        &run_hex_audit/1
      ],
      test: [
        "ecto.drop -r EctoTurbo.TestRepo --quiet",
        "ecto.create -r EctoTurbo.TestRepo --quiet",
        "ecto.migrate -r EctoTurbo.TestRepo --quiet",
        "test"
      ]
    ]
  end

  defp run_hex_outdated(_), do: Mix.shell().cmd("mix hex.outdated")
  defp run_hex_audit(_), do: Mix.shell().cmd("mix hex.audit")

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
