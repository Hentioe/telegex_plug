defmodule Telegex.Plug.Handler do
  @moduledoc """
  Message processing plug-in.
  """

  @type match_result :: {:match | :nomatch, Telegex.Plug.state()}

  defmacro __using__(_) do
    quote do
      use Telegex.Plug

      @behaviour Telegex.Plug.Handler

      @impl true
      def call(%{message: nil}, state) do
        {:ok, state}
      end

      @impl true
      def call(%{message: message}, state) do
        case match(message, state) do
          {:match, state} -> handle(message, state)
          {:nomatch, state} -> {:ignored, state}
        end
      end
    end
  end

  @callback match(message :: Telegex.Model.Message.t(), Telegex.Plug.state()) :: match_result()
  @callback handle(message :: Telegex.Model.Message.t(), Telegex.Plug.state()) ::
              Telegex.Plug.result()
end
