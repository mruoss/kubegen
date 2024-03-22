defmodule KubegenTest do
  use ExUnit.Case
  doctest Kubegen

  test "greets the world" do
    assert Kubegen.hello() == :world
  end
end
