defmodule Chax.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ChaxWeb.Telemetry,
      Chax.Repo,
      {DNSCluster, query: Application.get_env(:chax, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Chax.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Chax.Finch},
      ChaxWeb.Presence,
      # Start a worker by calling: Chax.Worker.start_link(arg)
      # {Chax.Worker, arg},
      # Start to serve requests, typically the last entry
      ChaxWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Chax.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ChaxWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
