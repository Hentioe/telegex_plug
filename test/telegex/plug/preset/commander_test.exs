defmodule Telegex.Plug.Preset.CommanderTest do
  use ExUnit.Case

  defmodule PingCommanderPlug do
    use Telegex.Plug.Preset, commander: :ping

    @impl true
    def handle(_message, state) do
      {:ok, Map.put(state, :response, "pong")}
    end
  end

  defmodule CustomMatchPingCommanderPlug do
    use Telegex.Plug.Preset, commander: :ping

    @impl true
    def match(text, state) do
      if String.starts_with?(text, "/ping") do
        {:match, state}
      else
        {:nomatch, state}
      end
    end

    @impl true
    def handle(_message, state) do
      {:ok, Map.put(state, :response, "pong")}
    end
  end

  test "call/2" do
    :ok = Telegex.Plug.update_username("test_bot")

    r = PingCommanderPlug.call(%{message: %{text: nil}}, %{})

    assert r == {:ignored, %{}}

    r = PingCommanderPlug.call(%{message: %{text: "/ping1"}}, %{})

    assert r == {:ignored, %{}}

    r = PingCommanderPlug.call(%{message: %{text: "/ping"}}, %{})

    assert r == {:ok, %{response: "pong"}}

    r = PingCommanderPlug.call(%{message: %{text: "/ping@"}}, %{})

    assert r == {:ignored, %{}}

    r = PingCommanderPlug.call(%{message: %{text: "/ping@test_bot"}}, %{})

    assert r == {:ok, %{response: "pong"}}

    r = CustomMatchPingCommanderPlug.call(%{message: %{text: nil}}, %{})

    assert r == {:ignored, %{}}

    r = CustomMatchPingCommanderPlug.call(%{message: %{text: "/ping1"}}, %{})

    assert r == {:ok, %{response: "pong"}}

    r = CustomMatchPingCommanderPlug.call(%{message: %{text: "/ping"}}, %{})

    assert r == {:ok, %{response: "pong"}}
  end
end
