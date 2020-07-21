defmodule Telegex.Plug.Preset.Preheater do
  @moduledoc """
  Preheating plug-in.
  """

  defmacro __using__(_) do
    quote do
      use Telegex.Plug

      @impl true
      def __preset__, do: :preheater
    end
  end
end
