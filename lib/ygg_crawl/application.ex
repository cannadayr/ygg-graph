defmodule YggCrawl.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    state = []
    children = [
      # Starts a worker by calling: YggCrawl.Worker.start_link(arg)
      # {YggCrawl.Worker, arg}
      {YggCrawl.Cache, state}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: YggCrawl.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
