defmodule Telegex.Plug.Presets.Caller do
  @moduledoc """
  Callback processing plug-in.
  """

  @typedoc "Match result."
  @type match_result :: :match | :nomatch

  defmacro __using__(prefix) when is_binary(prefix) do
    quote do
      use Telegex.Plug

      @behaviour Telegex.Plug.Presets.Caller
      @prefix unquote(prefix)

      @impl true
      def __preset__, do: :caller

      @impl true
      def match(data) do
        if String.starts_with?(data, @prefix) do
          :match
        else
          :nomatch
        end
      end

      @impl true
      def call(%{callback_query: nil} = _update, state) do
        {:ignored, state}
      end

      @impl true
      def call(%{callback_query: %{data: nil}} = _update, state) do
        {:ignored, state}
      end

      @impl true
      def call(%{callback_query: %{data: data} = callback_query} = _update, state) do
        case match(data) do
          :match -> handle(callback_query, state)
          :nomatch -> :ignored
        end
      end
    end
  end

  @doc """
  Match query callback data.

  This function can be automatically generated by `use` this module.
  """
  @callback match(data :: String.t()) :: match_result()

  @doc """
  Handle query callbacks.
  """
  @callback handle(
              callback_query :: Telegex.Model.CallbackQuery.t(),
              state :: Telegex.Plug.state()
            ) ::
              Telegex.Plug.stateless()
end
