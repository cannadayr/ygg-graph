defmodule Ygg.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    state = %{ "graph" => Graph.new() }
    children = [
      # Starts a worker by calling: Ygg.Worker.start_link(arg)
      # {Ygg.Worker, arg}
      {Ygg.Cache, state}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Ygg.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
