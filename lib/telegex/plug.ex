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
  @typedoc "The preset category."
  @type preset :: :preheater | :message_handler | :commander | :caller | :custom

  @doc """
  Pass update and call.
  """
  @callback call(update :: Telegex.Model.Update.t(), state :: state()) ::
              stateless() | stateful()

  @doc false
  @callback __preset__() :: preset

  @doc """
  Update the username of the bot.

  This function will improve the accuracy of command matching.
  """
  @spec update_username(String.t()) :: :ok
  def update_username(username) when is_binary(username) do
    Telegex.Plug.Cache.put(:username, username)
  end

  @doc """
  Get the username of the bot.

  Unless `Telegex.Plug.update_username/1` has been called, `nil` will be returned.
  """
  @spec get_usename :: String.t()
  def get_usename do
    Telegex.Plug.Cache.get(:username)
  end

  @doc """
  Get the preset type of a plug.
  """
  @spec __preset__(atom()) :: preset()
  def __preset__(module) do
    apply(module, :__preset__, [])
  end
end
