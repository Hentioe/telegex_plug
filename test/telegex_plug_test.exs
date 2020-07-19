defmodule TelegexPlugTest do
  use ExUnit.Case
  doctest TelegexPlug

  test "greets the world" do
    assert TelegexPlug.hello() == :world
  end
end
