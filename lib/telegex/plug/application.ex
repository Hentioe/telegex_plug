defmodule Telegex.Plug.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [Telegex.Plug.Cache, Telegex.Plug.Pipeline]

    opts = [strategy: :one_for_one, name: Telegex.Plug.Supervisor]

    Supervisor.start_link(children, opts)
  end
end
