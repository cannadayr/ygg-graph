# Ygg

Yggdrasil networked graph cache

git clone github.com/cannadayr/ygg-graph.git
cd ygg-graph
iex -S mix
iex(1)> Ygg.Dht.getself |> Ygg.Dht.addself
iex(1)> Ygg.Cache.noop

**TODO: Add (more) description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ygg` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ygg, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ygg](https://hexdocs.pm/ygg).

