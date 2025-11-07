defmodule D3Ex.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/Makesesama/d3.ex"

  def project do
    [
      app: :d3_ex,
      version: @version,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      name: "D3Ex",
      source_url: @source_url
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix_live_view, "~> 0.20.0"},
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    D3Ex provides seamless integration between D3.js and Phoenix LiveView
    using minimal state synchronization for high-performance client-side
    visualizations with server-side data management.
    """
  end

  defp package do
    [
      name: "d3_ex",
      files: ~w(lib priv .formatter.exs mix.exs README* LICENSE*),
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      main: "D3Ex",
      extras: ["README.md"]
    ]
  end
end
