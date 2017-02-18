defmodule UeberauthEveOnline.Mixfile do
  use Mix.Project

  @version "0.2.0"

  def project do
    [app: :ueberauth_eveonline,
     version: @version,
     name: "Ueberauth EveOnline",
     package: package(),
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     source_url: "https://github.com/bruce/ueberauth_eveonline",
     homepage_url: "https://github.com/bruce/ueberauth_eveonline",
     description: description(),
     deps: deps(),
     docs: docs()]
  end

  def application do
    [applications: [:logger, :ueberauth, :oauth2]]
  end

  defp deps do
    [
     {:oauth2, "~> 0.8"},
     {:ueberauth, "~> 0.4"},

     # dev/test only dependencies
     {:credo, "~> 0.5", only: [:dev, :test]},

     # docs dependencies
     {:earmark, "~> 0.2", only: :dev},
     {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp docs do
    [extras: ["README.md"]]
  end

  defp description do
    "An Ueberauth strategy for using EveOnline to authenticate your users."
  end

  defp package do
    [files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Bruce Williams", "Brian O'Grady"],
      licenses: ["MIT"],
      links: %{"GitHub": "https://eveonline.com/bruce/ueberauth_eveonline"}]
  end
end
