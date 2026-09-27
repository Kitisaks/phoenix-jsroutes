defmodule PhoenixJsroutes.MixProject do
  use Mix.Project

  def project do
    [
      app: :phoenix_jsroutes,
      version: "2.0.0",
      elixir: "~> 1.14",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:phoenix, "~> 1.8", only: :test},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false},
      {:styler, "~> 1.12", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    """
    Brings phoenix router helpers to your javascript code.
    """
  end

  defp package do
    [
      name: :phoenix_jsroutes,
      files: ["lib", "priv", "mix.exs", "README*", "LICENSE*"],
      licenses: ["MIT"],
      maintainers: ["Tiago Henrique Engel"],
      links: %{"GitHub" => "https://github.com/tiagoengel/phoenix-jsroutes"}
    ]
  end
end
