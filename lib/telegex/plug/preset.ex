defmodule Telegex.Plug.Preset do
  @moduledoc """
  Preset Plug-based abstraction.
  """

  defmacro __using__(opts) do
    opts = if is_list(opts), do: opts, else: [opts]

    opts |> hd() |> implement_preset()
  end

  defp implement_preset(:handler) do
    quote do
      use Telegex.Plug.Preset.Handler
    end
  end

  defp implement_preset(:preheater) do
    quote do
      use Telegex.Plug.Preset.Preheater
    end
  end

  defp implement_preset({:commander, command}) do
    quote do
      use Telegex.Plug.Preset.Commander, unquote(command)
    end
  end

  defp implement_preset({:caller, [{:prefix, prefix}]}) do
    quote do
      use Telegex.Plug.Preset.Caller, unquote(prefix)
    end
  end
end
