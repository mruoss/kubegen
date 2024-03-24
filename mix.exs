defmodule Kubegen.MixProject do
  use Mix.Project

  @app :kubegen
  @source_url "https://github.com/mruoss/#{@app}"
  @version "0.1.0"

  def project do
    [
      app: @app,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      preferred_cli_env: cli_env(),
      package: package(),
      test_coverage: [tool: ExCoveralls],
      dialyzer: dialyzer()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:kubereq, path: "../kubereq", optional: true},
      {:owl, "~> 0.9.0"},

      # Dev deps
      {:dialyxir, "~> 1.4.0", only: [:dev, :test], runtime: false},

      # Test deps
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:excoveralls, "~> 0.18", only: :test}
    ]
  end

  defp docs do
    [
      # The main page in the docs
      # main: "Pluggable.Token",
      source_ref: @version,
      source_url: @source_url,
      extras: [
        "README.md",
        "CHANGELOG.md"
      ]
    ]
  end

  defp cli_env do
    [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test,
      "coveralls.travis": :test,
      "coveralls.github": :test,
      "coveralls.xml": :test,
      "coveralls.json": :test
    ]
  end

  defp package do
    [
      name: @app,
      maintainers: ["Michael Ruoss"],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "https://hexdocs.pm/#{@app}/changelog.html",
        "Sponsor" => "https://github.com/sponsors/mruoss"
      },
      files: ["lib", "mix.exs", "README.md", "LICENSE", "CHANGELOG.md", ".formatter.exs"]
    ]
  end

  defp dialyzer do
    [
      ignore_warnings: ".dialyzer_ignore.exs",
      plt_core_path: "priv/plts",
      plt_file: {:no_warn, "priv/plts/#{@app}.plt"},
      plt_add_apps: [:mix]
    ]
  end
end
