defmodule Telegex.Plug.Presets.MessageHandler do
  @moduledoc """
  Handler for new messages.
  """

  @typedoc "Match result."
  @type match_result :: {:match | :nomatch, Telegex.Plug.state()}

  defmacro __using__(opts \\ []) do
    include_edited = Enum.member?(opts, :include_edited)

    quote do
      use Telegex.Plug

      @behaviour Telegex.Plug.Presets.MessageHandler

      @impl true
      def __preset__, do: :message_handler

      if unquote(include_edited) do
        # 当 `message` 和 `edited_message` 同时为 `nil` 时，忽略。
        @impl true
        def call(%{message: nil, edited_message: nil} = _update, state) do
          {:ignored, state}
        end

        @impl true
        def call(%{message: message, edited_message: edited_message} = _update, state) do
          message = message || edited_message

          case match(message, state) do
            {:match, state} -> handle(message, state)
            {:nomatch, state} -> {:ignored, state}
          end
        end
      else
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
