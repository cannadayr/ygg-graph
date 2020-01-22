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

  def get_by_pubkey(pubkey) do
    GenServer.call(:ygg, {:get_by_pubkey, pubkey})
  end

  def get_label(nodeid) do
    GenServer.call(:ygg, {:get_label, nodeid})
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

  def add_label(nodeid,label) do
    GenServer.cast(:ygg, {:add_label, nodeid, label})
  end

  # server
  def init(state) do
      {:ok, state}
  end

  # IO.inspect g, structs: false
  def handle_call(:noop, _from, state) do
    {:reply, state, state}
  end

  # Ygg.Dht.bootstrap_genargs |> Ygg.Dht.bootstrap
  def handle_call({:get_by_pubkey, pubkey}, _from, %{"graph" => g}) do

    require Logger
    gen_args = fn v,acc ->
      lab = fn(v) -> Graph.vertex_labels(g,v) end
      l = lab.(v)
      Logger.info("bpk1: #{pubkey}")
      case l do
        [%{"box_pub_key" => ^pubkey}] ->
          {:halt,[v|acc]}
        _ ->
          {:next,acc}
      end
    end

    accm = Graph.Reducers.Bfs.reduce(g,[],gen_args)
    {:reply, accm, %{"graph" => g} }
  end

  def handle_call({:get_label, nodeid}, _from, %{"graph" => g}) do
    label = Graph.vertex_labels(g,nodeid)
    {:reply, label, %{"graph" => g} }
  end

  def handle_call({:rm_label, node}, _from, %{"graph" => graph}) do
    {:reply, :ok, %{"graph" => Graph.remove_vertex_labels(graph,node)} }
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

  def handle_cast({:add_label,nodeid,label}, %{"graph" => g}) do
    {:noreply, %{"graph" => Graph.label_vertex(g,nodeid,label)} }
  end

end
