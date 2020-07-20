defmodule Telegex.Plug.Pipeline do
  @moduledoc """
  Plug pipeline.

  Cache plug modules in preset categories, and call plug in the pipeline in order.
  """

  use Agent

  defstruct handlers: [], commanders: [], callers: []

  @doc false
  def start_link(_) do
    Agent.start_link(fn -> %__MODULE__{} end, name: __MODULE__)
  end

  @doc """
  Install a plug into the pipeline.
  """
  def install(plug) when is_atom(plug) do
    update_fun = fn state ->
      case Telegex.Plug.__preset__(plug) do
        :handler -> Map.put(state, :handlers, state.handlers ++ [plug])
        :commander -> Map.put(state, :commanders, state.commanders ++ [plug])
        :caller -> Map.put(state, :callers, state.callers ++ [plug])
      end
    end

    Agent.update(__MODULE__, update_fun)
  end

  def install(plugs) when is_list(plugs) do
    Enum.map(plugs, &install/1)
  end

  @doc """
  Uninstall a plug in the pipeline.
  """
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

  @doc """
  Get a list of plugs whose preset category is `handler`.
  """
  @spec handlers :: [atom()]
  def handlers do
    Agent.get(__MODULE__, fn state -> state.handlers end)
  end

  @doc """
  Get a list of plugs whose preset category is `commander`.
  """
  @spec commanders :: [atom()]
  def commanders do
    Agent.get(__MODULE__, fn state -> state.commanders end)
  end

  @doc """
  Get a list of plugs whose preset category is `caller`.
  """
  @spec callers :: [atom()]
  def callers do
    Agent.get(__MODULE__, fn state -> state.callers end)
  end

  @typep snapshot :: {atom(), Telegex.Plug.stateless() | Telegex.Plug.stateful()}

  @doc """
  Call all plugs in the pipeline.

  This function always keeps the calling order of `commanders` => `handlers` -> `caller`. The state of the previous call result will be used before the stateful Plug is called.

  At the same time, this function will return all the call results of Plug, which are stored in order in a list.
  """
  @spec call(Telegex.Model.Update.t(), Telegex.Plug.state()) :: [snapshot()]
  def call(update, state) do
    stateful_snapshots = stateful_call(commanders() ++ handlers(), update, state)
    stateless_snapshots = stateless_call(callers(), update, state)

    stateful_snapshots ++ stateless_snapshots
  end

  @spec stateful_call([atom()], Telegex.Model.Update.t(), Telegex.Plug.state(), [snapshot()]) ::
          [snapshot()]
  defp stateful_call(plugs, update, state, snapshots \\ []) do
    {plug, plugs} = List.pop_at(plugs, 0)

    if plug do
      {_, {_, state}} = result = call_one(plug, update, state)
      stateful_call(plugs, update, state, snapshots ++ [result])
    else
      snapshots
    end
  end

  @spec stateless_call([atom()], Telegex.Model.Update.t(), Telegex.Plug.state()) ::
          [snapshot()]
  defp stateless_call(plugs, update, state) do
    Enum.map(plugs, &call_one(&1, update, state))
  end

  @spec call_one(atom(), Telegex.Model.Update.t(), Telegex.Plug.state()) :: snapshot()
  defp call_one(plug, update, state) do
    {plug, apply(plug, :call, [update, state])}
  end
end
