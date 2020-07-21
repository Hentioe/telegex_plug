defmodule Telegex.Plug.PipelineTest do
  use ExUnit.Case

  alias Telegex.Plug.Pipeline

  defmodule PingCommander do
    use Telegex.Plug.Preset, commander: :ping

    @impl true
    def handle(_message, state) do
      {:ok, Map.put(state, :response, "pong")}
    end
  end

  defmodule GetUpdateIDPreheater do
    use Telegex.Plug.Preset, :preheater

    @impl true
    def call(%{update_id: update_id} = _update, state) do
      {:ok, Map.put(state, :update_id, update_id)}
    end
  end

  defmodule GetMessageTextHandler do
    use Telegex.Plug.Preset, :handler

    @impl true
    def match(%{text: nil} = _message, state), do: {:nomatch, state}
    @impl true
    def match(%{text: ""} = _message, state), do: {:nomatch, state}
    @impl true
    def match(_message, state), do: {:match, state}

    @impl true
    def handle(%{text: text} = _message, state) do
      {:ok, Map.put(state, :text, text)}
    end
  end

  defmodule VerificationCaller do
    use Telegex.Plug.Preset, caller: [prefix: "verification:"]

    @impl true
    def handle(%{data: data} = _callback_query, state) do
      [_, chooese] = String.split(data, ":")
      chooese = String.to_integer(chooese)

      if chooese == 3 do
        {:ok, Map.put(state, :result, "success")}
      else
        {:ok, Map.put(state, :result, "faile")}
      end
    end
  end

  test "call/2" do
    Pipeline.install_all([GetUpdateIDPreheater])
    Pipeline.install_all([PingCommander])
    Pipeline.install_all([GetMessageTextHandler])
    Pipeline.install_all([VerificationCaller])

    update = %{update_id: 999, callback_query: nil, message: %{text: "/ping"}}
    snapshots = Pipeline.call(update, %{})

    assert snapshots == [
             {GetUpdateIDPreheater, {:ok, %{update_id: 999}}},
             {PingCommander, {:ok, %{update_id: 999, response: "pong"}}},
             {GetMessageTextHandler, {:ok, %{response: "pong", text: "/ping", update_id: 999}}},
             {VerificationCaller, {:ignored, %{update_id: 999}}}
           ]

    update = %{update_id: 999, callback_query: %{data: "verification:3"}, message: nil}
    snapshots = Pipeline.call(update, %{})

    assert snapshots == [
             {GetUpdateIDPreheater, {:ok, %{update_id: 999}}},
             {PingCommander, {:ignored, %{update_id: 999}}},
             {GetMessageTextHandler, {:ignored, %{update_id: 999}}},
             {VerificationCaller, {:ok, %{update_id: 999, result: "success"}}}
           ]
  end
end
