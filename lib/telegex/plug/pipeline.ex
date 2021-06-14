defmodule Telegex.Plug.Pipeline do
  @moduledoc """
  插件的管道。

  存储已安装的插件，并根据安装顺序依次调用插件。
  """

  use Agent

  alias Telegex.Plug
  alias Telegex.Model.Update
  alias Telegex.Plug.UnknownPresetError

  @type plug :: atom()
  @type t :: %__MODULE__{
          plugs: [plug]
        }

  @type install_opts :: [{:can_repeat, boolean}]

  defstruct plugs: []

  @doc false
  def start_link(_) do
    Agent.start_link(fn -> %__MODULE__{} end, name: __MODULE__)
  end

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

    if preset = unknown_preset(plug) do
      message = """
      The preset value `:#{preset}` of module `#{plug}` is incorrect. Currently supports: `:custom`, `:caller`, `:commander`, `:message_handler`, `:preheater`.
      """

      raise(UnknownPresetError, message)
    end

    if is_installed && !can_repeat do
      :already_installed
    else
      update_fun = fn state ->
        %{state | plugs: state.plugs ++ [plug]}
      end

      Agent.update(__MODULE__, update_fun)
    end
  end

  defp unknown_preset(plug) when is_atom(plug) do
    preset = Telegex.Plug.__preset__(plug)

    if preset in [
         :custom,
         :caller,
         :commander,
         :message_handler,
         :preheater
       ],
       do: nil,
       else: preset
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
  调用管道中的所有插件。

  此方法将按照插件的安装顺序依次调用。有状态插件产生的状态将向后传递，无状态插件不产生状态变化，但会接收变化后的状态值。
  注意：除了 `:preheater` 和 `:custom` 预设类型的插件，其它的任一有状态插件若进入处理流程（返回非 `:ignored` 的值），后续所有的无状态插件将不再实际调用。

  返回所有插件的调用结果快照。
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

        # 若产生消费，将修改 `is_consumed` 标记以阻止对后续无状态插件的调用。
        # 注意，消费变量 `is_consumed` 只要被标记为 `true`，就不能被改回 `false`，也不需要再更改。
        is_consumed = is_consumed || result != :ignored

        {returns_state, snapshots ++ [snapshot], is_consumed}

      preset in [:preheater, :custom] ->
        {_plug, {_result, returns_state}} = snapshot = call_one(plug, update, stateful_state)

        # 注意和有状态调用的区别：`:custom` 和 `:preheater` 并不修改消费标记，不会影响对 `:caller` 或其它无状态插件的调用。
        {returns_state, snapshots ++ [snapshot], false}

      true ->
        if is_consumed do
          # 已被有状态调用消费过，不进入调用流程。直接返回 `:ignored` 和上一个插件产生的状态。
          {stateful_state, snapshots ++ [{plug, {:ignored, stateful_state}}], false}
        else
          {_plug, result} = snapshot = call_one(plug, update, stateful_state)

          # 无状态插件也可能修改消费标记，并阻止下一个无状态插件的执行。
          is_consumed = is_consumed || result != :ignored

          {stateful_state, snapshots ++ [snapshot], is_consumed}
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
