defmodule Telegex.Plug do
  @moduledoc """
  Updates processing plug-in.
  """

  defmacro __using__(_) do
    quote do
      @behaviour Telegex.Plug
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
