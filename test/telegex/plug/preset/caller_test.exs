defmodule Telegex.Plug.Preset.CallerTest do
  use ExUnit.Case

  defmodule VerificationCallerPlug do
    use Telegex.Plug.Preset, caller: [prefix: "verification:"]

    @impl true
    def handle(%{data: data} = _callback_query, _state) do
      [_, chooese] = String.split(data, ":")

      try do
        _ = String.to_integer(chooese)

        :ok
      rescue
        _ -> :error
      end
    end
  end

  test "call/2" do
    r = VerificationCallerPlug.call(%{callback_query: %{data: "menu:back"}}, %{})

    assert r == :ignored

    r = VerificationCallerPlug.call(%{callback_query: %{data: "verification:a"}}, %{})

    assert r == :error

    r = VerificationCallerPlug.call(%{callback_query: %{data: "verification:3"}}, %{})

    assert r == :ok
  end
end
