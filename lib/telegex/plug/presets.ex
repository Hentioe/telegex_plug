defmodule Telegex.Plug.Presets do
  @moduledoc """
  Preset Plug-based abstraction.
  """

  defmacro __using__(opts) do
    implement_preset(opts)
  end

  defp implement_preset(:message_handler) do
    quote do
      use Telegex.Plug.Presets.MessageHandler
    end
  end

  defp implement_preset(:preheater) do
    quote do
      use Telegex.Plug.Presets.Preheater
    end
  end

  defp implement_preset([{:commander, command}]) do
    quote do
      use Telegex.Plug.Presets.Commander, unquote(command)
    end
  end

  defp implement_preset([{:caller, [{:prefix, prefix}]}]) do
    quote do
      use Telegex.Plug.Presets.Caller, unquote(prefix)
    end
  end
end
