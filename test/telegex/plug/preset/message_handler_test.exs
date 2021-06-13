defmodule Telegex.Plug.Presets.MessageHandlerTest do
  use ExUnit.Case

  defmodule UpcaseMessageTextPlug do
    use Telegex.Plug.Presets, :message_handler

    @impl true
    def match(%{text: nil} = _message, state) do
      {:nomatch, state}
    end

    @impl true
    def match(%{text: ""} = _message, state) do
      {:nomatch, state}
    end

    @impl true
    def match(%{text: text} = _message, state) do
      {:match, Map.put(state, :text, text)}
    end

    @impl true
    def handle(_message, %{text: text} = state) do
      {:ok, Map.put(state, :text, String.upcase(text))}
    end
  end

  test "call/2" do
    r = UpcaseMessageTextPlug.call(%{message: %{text: nil}}, %{})

    assert r == {:ignored, %{}}

    r = UpcaseMessageTextPlug.call(%{message: %{text: ""}}, %{})

    assert r == {:ignored, %{}}

    r = UpcaseMessageTextPlug.call(%{message: %{text: "Hello world."}}, %{})

    assert r == {:ok, %{text: "HELLO WORLD."}}
  end
end
