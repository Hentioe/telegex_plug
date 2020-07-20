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

  defmodule GetUpdateIDHandler do
    use Telegex.Plug

    @impl true
    def __preset__, do: :handler

    @impl true
    def call(%{update_id: update_id} = _update, state) do
      {:ok, Map.put(state, :update_id, update_id)}
    end
  end

  defmodule GetMessageTextHandler do
    use Telegex.Plug.Preset, [:handler]

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
    Pipeline.install([PingCommander])
    Pipeline.install([GetUpdateIDHandler, GetMessageTextHandler])
    Pipeline.install([VerificationCaller])

    update = %{update_id: 999, callback_query: nil, message: %{text: "/ping"}}
    snapshots = Pipeline.call(update, %{})

    assert snapshots == [
             {PingCommander, {:ok, %{response: "pong"}}},
             {GetUpdateIDHandler, {:ok, %{response: "pong", update_id: 999}}},
             {GetMessageTextHandler, {:ok, %{response: "pong", text: "/ping", update_id: 999}}},
             {VerificationCaller, {:ignored, %{}}}
           ]

    update = %{update_id: 999, callback_query: %{data: "verification:3"}, message: nil}
    snapshots = Pipeline.call(update, %{})

    assert snapshots == [
             {PingCommander, {:ignored, %{}}},
             {GetUpdateIDHandler, {:ok, %{update_id: 999}}},
             {GetMessageTextHandler, {:ignored, %{update_id: 999}}},
             {VerificationCaller, {:ok, %{result: "success"}}}
           ]
  end
end
