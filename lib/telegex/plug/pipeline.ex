defmodule Telegex.Plug.Pipeline do
  @moduledoc false

  use Agent

  defstruct handlers: [], commanders: [], callers: []

  def start_link(_) do
    Agent.start_link(fn -> %__MODULE__{} end, name: __MODULE__)
  end

  def install(plug) do
    update_fun = fn state ->
      case Telegex.Plug.__preset__(plug) do
        :handler -> Map.put(state, :handlers, state.handlers ++ [plug])
        :commander -> Map.put(state, :commanders, state.commanders ++ [plug])
        :caller -> Map.put(state, :callers, state.callers ++ [plug])
      end
    end

    Agent.update(__MODULE__, update_fun)
  end

  def uninstall(plug) do
    filter_fun = fn current_plug -> current_plug != plug end

    update_fun = fn state ->
      case Telegex.Plug.__preset__(plug) do
        :handler -> Enum.filter(state.handlers, filter_fun)
        :commander -> Enum.filter(state.commanders, filter_fun)
        :caller -> Enum.filter(state.callers, filter_fun)
      end
    end

    Agent.update(__MODULE__, update_fun)
  end

  @spec handlers :: [atom()]
  def handlers do
    Agent.get(__MODULE__, fn state -> state.handlers end)
  end

  @spec commnaders :: [atom()]
  def commnaders do
    Agent.get(__MODULE__, fn state -> state.commnaders end)
  end

  @spec callers :: [atom()]
  def callers do
    Agent.get(__MODULE__, fn state -> state.callers end)
  end
end
