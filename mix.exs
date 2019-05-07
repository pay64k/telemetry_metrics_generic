defmodule TelemetryMetricsGeneric.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :telemetry_metrics_generic,
      version: @version,
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:telemetry_metrics, "~> 0.2"},
      {:stream_data, "~> 0.4", only: :test},
      {:dialyxir, "~> 0.5", only: :test, runtime: false},
      {:ex_doc, "~> 0.19", only: :docs}
    ]
  end
end
