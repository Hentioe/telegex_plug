defmodule Telegex.Plug.Preset.Handler do
  @moduledoc """
  Message processing plug-in.
  """

  @typedoc "Match results."
  @type match_result :: {:match | :nomatch, Telegex.Plug.state()}

  defmacro __using__(_) do
    quote do
      use Telegex.Plug

      @behaviour Telegex.Plug.Preset.Handler

      @impl true
      def __preset__, do: :handler

      @impl true
      def call(%{message: nil} = _update, state) do
        {:ignored, state}
      end

      @impl true
      def call(%{message: message} = _update, state) do
        case match(message, state) do
          {:match, state} -> handle(message, state)
          {:nomatch, state} -> {:ignored, state}
        end
      end
    end
  end

  @doc """
  Match messages.
  """
  @callback match(message :: Telegex.Model.Message.t(), Telegex.Plug.state()) :: match_result()

  @doc """
  Handle messages.
  """
  @callback handle(message :: Telegex.Model.Message.t(), Telegex.Plug.state()) ::
              Telegex.Plug.stateful()
end
