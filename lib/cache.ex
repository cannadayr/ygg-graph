defmodule YggCrawl.Cache do
  use GenServer

  # client
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: :ygg_crawl)
  end

  def noop do
    GenServer.call(:ygg_crawl, :noop)
  end

  def add_node(node) do
    GenServer.cast(:ygg_crawl, {:add_node, node})
  end

  # server
  def init(state) do
      {:ok, state}
  end

  def handle_call(:noop, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:add_node, node},%{"graph" => graph}) do
    {:noreply, %{"graph" => Graph.add_vertex(graph,node) } }
  end
end
