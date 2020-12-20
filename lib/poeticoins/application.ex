defmodule Poeticoins.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      PoeticoinsWeb.Telemetry,
      {Phoenix.PubSub, name: Poeticoins.PubSub},
      {Poeticoins.Historical, name: Poeticoins.Historical},
      {Poeticoins.Exchanges.Supervisor, name: Poeticoins.Exchanges.Supervisor},
      PoeticoinsWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Poeticoins.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    PoeticoinsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
