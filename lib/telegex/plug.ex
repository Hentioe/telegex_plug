defmodule Telegex.Plug do
  @moduledoc """
  Updates processing plug-in.
  """

  defmacro __using__(opts) do
    if Enum.empty?(opts), do: implement_plug(), else: implement_preset(hd(opts))
  end

  defp implement_plug do
    quote do
      @behaviour Telegex.Plug
    end
  end

  defp implement_preset(:handler) do
    quote do
      use Telegex.Plug.Handler
    end
  end

  defp implement_preset({:commander, command}) do
    quote do
      use Telegex.Plug.Commander, unquote(command)
    end
  end

  defp implement_preset({:caller, [{:prefix, prefix}]}) do
    quote do
      use Telegex.Plug.Caller, unquote(prefix)
    end
  end

  @typedoc "State data."
  @type state :: any()
  @typedoc "The stateless call result directly returns the type."
  @type stateless :: :ok | :error | :ignored
  @typedoc "Stateful call result, return type and new state."
  @type stateful :: {stateless(), state()}

  @doc """
  Pass update and call.
  """
  @callback call(update :: Telegex.Model.Update.t(), state :: state()) ::
              stateless() | stateful()
end
