defmodule Telegex.Plug.PipelineTest do
  use ExUnit.Case

  alias Telegex.Plug.Pipeline

  defmodule RespPingPlug do
    use Telegex.Plug.Presets, commander: :ping

    @impl true
    def handle(_message, state) do
      {:ok, Map.put(state, :response, "pong")}
    end
  end

  defmodule InitGetUpdateIdPlug do
    use Telegex.Plug.Presets, :preheater

    @impl true
    def call(%{update_id: update_id} = _update, state) do
      {:ok, Map.put(state, :update_id, update_id)}
    end
  end

  defmodule HandleMessageTextGetPlug do
    use Telegex.Plug.Presets, :message_handler

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

  defmodule CallVerificationPlug do
    use Telegex.Plug.Presets, caller: [prefix: "verification:"]

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
    Pipeline.install_all([InitGetUpdateIdPlug])
    Pipeline.install_all([RespPingPlug])
    Pipeline.install_all([HandleMessageTextGetPlug])
    Pipeline.install_all([CallVerificationPlug])

    update = %{update_id: 999, callback_query: nil, message: %{text: "/ping"}}
    snapshots = Pipeline.call(update, %{})

    assert snapshots == [
             {InitGetUpdateIdPlug, {:ok, %{update_id: 999}}},
             {RespPingPlug, {:ok, %{update_id: 999, response: "pong"}}},
             {HandleMessageTextGetPlug,
              {:ok, %{response: "pong", text: "/ping", update_id: 999}}},
             {CallVerificationPlug,
              {:ignored, %{update_id: 999, response: "pong", text: "/ping"}}}
           ]

    update = %{update_id: 999, callback_query: %{data: "verification:3"}, message: nil}
    snapshots = Pipeline.call(update, %{})

    assert snapshots == [
             {InitGetUpdateIdPlug, {:ok, %{update_id: 999}}},
             {RespPingPlug, {:ignored, %{update_id: 999}}},
             {HandleMessageTextGetPlug, {:ignored, %{update_id: 999}}},
             {CallVerificationPlug, {:ok, %{update_id: 999, result: "success"}}}
           ]
  end
end
