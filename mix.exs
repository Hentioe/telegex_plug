defmodule TelegexPlug.MixProject do
  use Mix.Project

  @description "The abstract design of Telegram's update processing."
  @version "0.1.0"

  def project do
    [
      app: :telegex_plug,
      version: @version,
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: @description,
      package: package(),
      name: "Telegex.Plug",
      source_url: "https://github.com/Hentioe/telegex_plug",
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
      links: %{"GitHub" => "https://github.com/Hentioe/telegex_marked"}
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
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:telegex, "~> 0.1.0", only: [:dev, :test]}
    ]
  end
end
