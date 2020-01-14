defmodule YggCrawl.Dht do
  @path Application.fetch_env!(:ygg_crawl, :socket)
  @opt [:binary, recbuf: 8192, active: false, reuseaddr: true]

  def getself do
    {:ok, sock} = :gen_tcp.connect({:local, @path}, 0, @opt)
    :ok = sock |> :gen_tcp.send(~s({"request":"getself"}))
    {:ok, resp} = sock |> :gen_tcp.recv(0)
    resp |> Jason.decode
  end

end
