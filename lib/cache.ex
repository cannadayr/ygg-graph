defmodule YggCrawl.Cache do
  use GenServer

  # client
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: :ygg_crawl)
  end

  def noop do
    GenServer.call(:ygg_crawl, :noop)
  end

  # server
  def init(init_arg) do
      {:ok, init_arg}
  end

  def handle_call(:noop, _from, state) do
    {:reply, state, state}
  end
end
