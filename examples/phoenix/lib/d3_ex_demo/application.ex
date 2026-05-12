defmodule D3ExDemo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      D3ExDemoWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:d3_ex_demo, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: D3ExDemo.PubSub},
      # Start a worker by calling: D3ExDemo.Worker.start_link(arg)
      # {D3ExDemo.Worker, arg},
      # Start to serve requests, typically the last entry
      D3ExDemoWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: D3ExDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    D3ExDemoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
