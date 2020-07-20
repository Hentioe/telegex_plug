defmodule Telegex.PlugTest do
  use ExUnit.Case

  defmodule GetValidUpdateIDPlug do
    use Telegex.Plug

    @impl true
    def call(%{update_id: update_id} = _update, state) when update_id <= 0 do
      {:ignored, state}
    end

    @impl true
    def call(%{update_id: update_id} = _update, state) when update_id > 99 do
      {:error, state}
    end

    @impl true
    def call(%{update_id: update_id} = _update, state) do
      {:ok, Map.put(state, :update_id, update_id)}
    end

    @impl true
    def __preset__ do
      :handler
    end
  end

  test "call/2" do
    r = GetValidUpdateIDPlug.call(%{update_id: 0}, %{})

    assert r == {:ignored, %{}}

    r = GetValidUpdateIDPlug.call(%{update_id: 1}, %{})

    assert r == {:ok, %{update_id: 1}}

    r = GetValidUpdateIDPlug.call(%{update_id: 10_000}, %{})

    assert r == {:error, %{}}
  end
end
