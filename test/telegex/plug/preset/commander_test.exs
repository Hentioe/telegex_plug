defmodule Telegex.Plug.Presets.CommanderTest do
  use ExUnit.Case

  import Telegex.Plug.Factory

  defmodule PingCommanderPlug do
    use Telegex.Plug.Presets, commander: :ping

    @impl true
    def handle(_message, state) do
      {:ok, Map.put(state, :response, "pong")}
    end
  end

  defmodule CustomMatchPingCommanderPlug do
    use Telegex.Plug.Presets, commander: :ping

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

    r = PingCommanderPlug.call(build_message_update(nil), %{})

    assert r == {:ignored, %{}}

    r = PingCommanderPlug.call(build_message_update("/ping1"), %{})

    assert r == {:ignored, %{}}

    r = PingCommanderPlug.call(build_message_update("/ping"), %{})

    assert r == {:ok, %{response: "pong"}}

    r = PingCommanderPlug.call(build_message_update("/ping@"), %{})

    assert r == {:ignored, %{}}

    r = PingCommanderPlug.call(build_message_update("/ping@test_bot"), %{})

    assert r == {:ok, %{response: "pong"}}

    r = CustomMatchPingCommanderPlug.call(build_message_update(nil), %{})

    assert r == {:ignored, %{}}

    r = CustomMatchPingCommanderPlug.call(build_message_update("/ping1"), %{})

    assert r == {:ok, %{response: "pong"}}

    r = CustomMatchPingCommanderPlug.call(build_message_update("/ping"), %{})

    assert r == {:ok, %{response: "pong"}}
  end
end
