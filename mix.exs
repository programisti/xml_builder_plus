defmodule XmlBuilderPlus.Mixfile do
  use Mix.Project

  def project do
    [app: :xml_builder_plus,
     version: "0.0.5",
     elixir: ">= 0.14.0",
     deps: deps,
     package: [
       maintainers: ["Zaali Kavelashvili", "Eloy Fernández", "Jorge Díaz"],
       licenses: ["MIT"],
       links: %{github: "https://github.com/AirGateway/xml_builder_plus"}
     ],
     description: """
     XML builder for Elixir (with namespaces support)
     """
   ]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: []]
  end

  # Dependencies can be hex.pm packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1"}
  #
  # Type `mix help deps` for more examples and namespace
  defp deps do
    [{:ex_doc, github: "elixir-lang/ex_doc", only: :dev}]
  end
end
