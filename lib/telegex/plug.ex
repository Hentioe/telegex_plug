defmodule Telegex.Plug do
  @moduledoc """
  Updates processing plug-in.
  """

  defmacro __using__(opts) do
    if Enum.empty?(opts), do: implement_plug(), else: implement_preset(opts)
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

  @typedoc "Type of state passed between plugins"
  @type state :: any()
  @typedoc "The return value type of `Telegex.Plug.call/2`"
  @type result :: {:ok | :error | :ignored, Telegex.Plug.state()}

  @callback call(state :: state(), update :: Telegex.Model.Update.t()) :: result()
end
