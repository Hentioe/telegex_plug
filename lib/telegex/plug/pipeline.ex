defmodule Telegex.Plug.Pipeline do
  @moduledoc """
  Plug pipeline.

  Cache plug modules in preset categories, and call plug in the pipeline in order.
  """

  use Agent

  alias Telegex.Plug
  alias Telegex.Model.Update

  @type plug :: atom()
  @type t :: %__MODULE__{
          plugs: [plug]
        }

  defstruct plugs: []

  @doc false
  def start_link(_) do
    Agent.start_link(fn -> %__MODULE__{} end, name: __MODULE__)
  end

  @type install_opts :: [{:can_repeat, boolean}]

  @doc """
  Install a plug into the pipeline.

  ## Arguments
  - `plug`: The name of the module that implements the plug.
  - `options`
    - `can_repeat`: Whether to allow repeated installation. The default value is `false`, and repeated installation is not allowed.

  *Notes*: If the value of the optional parameter `can_repeat` is `false` but an existing plug is installed, it will return `:already_installed`.
  """
  @spec install(plug, install_opts) :: :ok | :already_installed | :unknown_preset
  def install(plug, options \\ []) when is_atom(plug) and is_list(options) do
    can_repeat = Keyword.get(options, :can_repeat, false)

    is_installed = Enum.member?(plugs(), plug)

    unless Telegex.Plug.__preset__(plug) in [
             :custom,
             :caller,
             :commander,
             :message_handler,
             :preheater
           ],
           do: raise("Unknown preset: `#{plug}`")

    if is_installed && !can_repeat do
      :already_installed
    else
      update_fun = fn state ->
        %{state | plugs: state.plugs ++ [plug]}
      end

      Agent.update(__MODULE__, update_fun)
    end
  end

  @doc """
  Install multiple plugs into the pipeline.

  ## Arguments
  - `plugs`: List of `plug()`.
  - `options`: Refer to the `options` parameter in the `Telegex.Pipeline.install/2` function.
  """
  def install_all(plugs, options \\ []) when is_list(plugs) do
    Enum.map(plugs, &install(&1, options))
  end

  @doc """
  Uninstall a plug in the pipeline.
  """
  def uninstall(plug) do
    filter_fun = fn current_plug -> current_plug != plug end

    Agent.update(__MODULE__, fn state ->
      %{state | plugs: Enum.filter(state.plugs, filter_fun)}
    end)
  end

  @typep snapshot :: {atom(), Plug.stateless() | Plug.stateful()}

  @doc """
  Call all plugs in the pipeline.

  This function always keeps the calling order of `commanders` => `handlers` -> `caller`. The state of the previous call result will be used before the stateful Plug is called.

  At the same time, this function will return all the call results of Plug, which are stored in order in a list.
  """
  @spec call(Update.t(), Plug.state()) :: [snapshot()]
  def call(update, state) do
    {_, snapshots, _} = Enum.reduce(plugs(), {state, [], false}, &reduce_call(update, &1, &2))

    snapshots
  end

  defp reduce_call(update, plug, {stateful_state, snapshots, is_consumed}) do
    preset = Telegex.Plug.__preset__(plug)

    cond do
      preset in [:commander, :message_handler] ->
        # 有状态的调用。
        {_plug, {result, returns_state}} = snapshot = call_one(plug, update, stateful_state)

        {returns_state, snapshots ++ [snapshot], result != :ignored}

      preset in [:preheater, :custom] ->
        {_plug, {_result, returns_state}} = snapshot = call_one(plug, update, stateful_state)

        {returns_state, snapshots ++ [snapshot], false}

      true ->
        if is_consumed do
          {stateful_state, snapshots ++ [{plug, {:ignored, stateful_state}}], false}
        else
          {_plug, _} = snapshot = call_one(plug, update, stateful_state)

          {stateful_state, snapshots ++ [snapshot], true}
        end
    end
  end

  def plugs() do
    Agent.get(__MODULE__, fn state -> state.plugs end)
  end

  @spec call_one(atom(), Update.t(), Plug.state()) :: snapshot()
  defp call_one(plug, update, state) do
    {plug, apply(plug, :call, [update, state])}
  end
end
