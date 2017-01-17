defmodule Backtrex.Mixfile do
  use Mix.Project

  def project do
    [app: :backtrex,
     version: "0.1.2",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     elixirc_options: [warnings_as_errors: true],
     description: description(),
     package: package(),
     deps: deps()]
  end

  def application do
    [extra_applications: [:logger, :eflame],
     applications: [:logger]]   # format expected by Elixir 1.3
  end

  defp deps do
    [
      {:credo, "~> 0.5", only: [:dev, :test]},
      {:dialyxir, "~> 0.4", only: [:dev], runtime: false},
      {:eflame, ~r/.*/, git: "https://github.com/proger/eflame.git", compile: "rebar compile"},
      {:ex_doc, "~> 0.14", only: :dev},
    ]
  end

  defp description do
    """
    Backtracking behaviour to solve discrete problems by brute force.
    """
  end

  defp package do
    [
      name: :backtrex,
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Jacob Mitchell"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => "https://github.com/jmitchell/backtrex",
        "Docs" => "https://hexdocs.pm/backtrex/0.1.0",
      },
    ]
  end
end
