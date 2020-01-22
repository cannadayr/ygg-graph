defmodule Ygg.Dht do
  @path Application.fetch_env!(:ygg, :socket)
  @opt [:binary, recbuf: 8192, active: false, reuseaddr: true]

  def getself do
    {:ok, sock} = :gen_tcp.connect({:local, @path}, 0, @opt)
    :ok = sock |> :gen_tcp.send(~s({"request":"getself"}))
    {:ok, resp} = sock |> :gen_tcp.recv(0)
    resp |> Jason.decode
  end

  def addself({:ok,%{"response" => %{"self" => myself} } }) do
    node  = Map.keys(myself) |> List.first
    label = Map.values(myself) |> List.first
    Ygg.Cache.add_node(node,label)
  end

  def getdht do
    {:ok, sock} = :gen_tcp.connect({:local, @path}, 0, @opt)
    :ok = sock |> :gen_tcp.send(~s({"request":"getdht"}))
    {:ok, resp} = sock |> :gen_tcp.recv(0)
    resp |> Jason.decode
  end

  # Ygg.Dht.getdht |> Ygg.Dht.addneighbors(Ygg.Dht.getself())
  def addneighbors({:ok,%{"response" => %{"dht" => n}}},{:ok,%{"response" => %{"self" => s}}}) do
    n |> fn(n) -> for j <- n do {r,l} = j; Ygg.Cache.add_node(r,l) end end.() # add nodes
    for i <- s |> Map.keys, j <- n |> Map.keys do Ygg.Cache.add_edge(i,j) end # add edges
  end

  def dhtping(box_pub_key,coords) do
    {:ok, sock} = :gen_tcp.connect({:local, @path}, 0, @opt)
    {:ok, req} = Jason.encode(%{"request" => "dhtping", "box_pub_key" => box_pub_key, "coords" => coords})
    :ok = sock |> :gen_tcp.send(req)
    {:ok, resp} = sock |> :gen_tcp.recv(0)
    resp |> Jason.decode
  end

  def bootstrap_genargs do
    %{"graph" => g} = Ygg.Cache.noop
    Ygg.Dht.getself |> Ygg.Dht.addself
    Ygg.Dht.getdht |> Ygg.Dht.addneighbors(Ygg.Dht.getself)
    lab = fn(v) -> Graph.vertex_labels(g,v) end # get labels
    Graph.Reducers.Bfs.reduce(g,[],
    fn v,acc -> l = lab.(v);
      case l do
        [%{"subnet"=>_}] ->
          {:next,acc} # skip ourselves
        [%{"box_pub_key"=>b,"coords"=>c}] ->
          {:next, [{b,c}|acc]}
      end
    end)
  end

  def bootstrap(args) do

    ping  = fn(x) ->
      {b,c} = x
      Ygg.Dht.dhtping(b,c)
    end

    nodes = fn(x) ->
      {:ok,%{"response"=>%{"nodes"=>n}}} = x
      n
    end

    add_set = fn(x) ->
      add = fn(x) ->
        {a,b} = x
        Ygg.Cache.add_node(a,b)
      end
      Enum.map(x,add)
    end

    args
    |> Enum.map(&(Task.async(fn -> ping.(&1) end)))
    |> Enum.map(&(Task.await(&1,30000)))
    |> Enum.map(nodes)
    |> Enum.map(add_set)
  end

  def gen_crawl(%{"graph" => g}) do
    lab = fn(v) -> Graph.vertex_labels(g,v) end
    gen_args = fn v,acc ->
      l = lab.(v)
      case l do
        [%{"subnet"=>_}] ->
          {:next,acc}
        [%{"last_seen" =>_}] ->
          {:next,acc}
        [%{"visited" =>_}] ->
          {:next,acc}
        [%{"box_pub_key" => b, "coords" => c}] ->
          {:next,[{b,c}|acc]}
        _ ->
          {:next,acc}
      end
    end
    Graph.Reducers.Bfs.reduce(g,[],gen_args)
  end

  def crawl(nnaddrs) do
    ping = fn(x) ->
      {b,c} = x
      Ygg.Dht.dhtping(b,c)
    end
    nnaddrs
    |> Enum.map(&(Task.async(fn -> ping.(&1) end)))
    |> Enum.map(&(Task.await(&1,30000)))
    |> Enum.filter(&match?({:ok, %{"status"=>"success"}}, &1))
  end

  def addcrawl(resp) do

    require Logger
    nodes = fn(x) ->
      {:ok,%{"request" => %{"box_pub_key"=>bpk},"response"=>%{"nodes"=>n}}} = x

      Logger.info("bpk: #{bpk}")
      [id] = Ygg.Cache.get_by_pubkey(bpk)
      [label] = Ygg.Cache.get_label(id)
      ll = Map.put(label,"visited",true)
      Ygg.Cache.rm_label(id)
      Ygg.Cache.add_label(id,ll)
      # graph = Graph.label_vertex(graph, :v1, [:label1])
      #Ygg.Cache.add_node(id,ll)

      {id,n}
    end
    add_set = fn(x) ->
      {f,t} = x
      mut = fn(y) ->
        {n,l} = y
        Ygg.Cache.rm_label(n) # don't use cast! increases memory significantly! #TODO figure out why
        Ygg.Cache.add_node(n,l)
        Ygg.Cache.add_edge(f,n)
        #{{n},{n,l},{f,n}}
      end
      Enum.map(t,mut)
    end
    resp
    |> Enum.map(nodes)
    |> Enum.map(add_set)

  end
end
