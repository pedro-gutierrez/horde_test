defmodule HordeTestTest do
  use ExUnit.Case
  doctest HordeTest

  test "greets the world" do
    assert HordeTest.hello() == :world
  end
end
