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
    |> Enum.map(ping)
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
        [%{"box_pub_key" => b, "coords" => c}] ->
          {:next,[{b,c}|acc]}
      end
    end
    Graph.Reducers.Bfs.reduce(g,[],gen_args)
  end

  def crawl(nnaddrs) do
    ping = fn(x) ->
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
    nnaddrs
    |> Enum.map(ping)
    |> Enum.filter(&match?({:ok, %{"status"=>"success"}}, &1))
    |> Enum.map(nodes)
    |> Enum.map(add_set)
  end

end
