defmodule IascCargarapida.MixProject do
  use Mix.Project

  def project do
    [
      app: :iasc_cargarapida,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :eex, :wx, :observer, :runtime_tools],
      mod: {CargaRapida.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:libcluster, "~> 3.5"},
      {:horde, "~> 0.9.1"},
      {:plug_cowboy, "~> 2.7.4"},
      {:uuid, "~> 1.1.8"}
    ]
  end
end
