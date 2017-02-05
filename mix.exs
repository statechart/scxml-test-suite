defmodule ScxmlTestSuite.Mixfile do
  use Mix.Project

  def project do
    [app: :scxml_test_suite,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:etude, "~> 1.0", only: [:dev, :test]},
     {:etude_request, "~> 0.2", only: [:dev, :test]},
     {:poison, ">= 3.0.0", only: [:dev, :test]}]
  end
end
