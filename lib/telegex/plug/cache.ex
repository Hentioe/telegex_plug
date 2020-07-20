defmodule Telegex.Plug.Cache do
  @moduledoc false

  use Agent

  def start_link(_) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @spec put(any(), any()) :: :ok
  def put(key, value) do
    Agent.update(__MODULE__, fn state -> Map.put(state, key, value) end)
  end

  @spec get(any()) :: any()
  def get(key) do
    Agent.get(__MODULE__, fn state -> state[key] end)
  end
end
