defmodule Ygg.Cache do
  use GenServer

  # client
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: :ygg)
  end

  def noop do
    GenServer.call(:ygg, :noop)
  end

  def rm_label(node) do
    GenServer.call(:ygg, {:rm_label, node})
  end

  def add_node(node) do
    GenServer.cast(:ygg, {:add_node, node})
  end

  def add_node(node,label) do
    GenServer.cast(:ygg, {:add_node, node, label})
  end

  def add_edge(from,to) do
    GenServer.cast(:ygg, {:add_edge, from, to})
  end

  # server
  def init(state) do
      {:ok, state}
  end

  # IO.inspect g, structs: false
  def handle_call(:noop, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:rm_label, node}, _from, %{"graph" => graph}) do
    {:reply, %{"graph" => Graph.remove_vertex_labels(graph,node)}, %{"graph" => graph} }
  end

  def handle_cast({:add_node, node},%{"graph" => graph}) do
    {:noreply, %{"graph" => Graph.add_vertex(graph,node) } }
  end

  def handle_cast({:add_node, node, label},%{"graph" => graph}) do
    {:noreply, %{"graph" => Graph.add_vertex(graph,node,label) } }
  end

  def handle_cast({:add_edge, from, to}, %{"graph" => graph}) do
    {:noreply, %{"graph" => Graph.add_edge(graph,from,to)} }
  end

end
