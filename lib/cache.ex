defmodule Ygg.Cache do
  use GenServer

  # client
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: :ygg)
  end

  def noop do
    GenServer.call(:ygg, :noop)
  end

  def add_node(node) do
    GenServer.cast(:ygg, {:add_node, node})
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
