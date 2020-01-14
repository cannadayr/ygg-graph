defmodule YggTest do
  use ExUnit.Case
  doctest Ygg

  test "greets the world" do
    assert Ygg.hello() == :world
  end
end
