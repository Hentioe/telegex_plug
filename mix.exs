defmodule TelegexPlug.MixProject do
  use Mix.Project

  @description "Plug-in design of Telegex."
  @version "0.3.0"

  def project do
    [
      app: :telegex_plug,
      version: @version,
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: @description,
      package: package(),
      name: "Telegex.Plug",
      source_url: "https://github.com/telegex/telegex_plug",
      docs: [
        # The main page in the docs
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/telegex/telegex_plug"}
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Telegex.Plug.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev], runtime: false},
      {:telegex, "~> 0.1", only: [:dev, :test]}
    ]
  end
end
