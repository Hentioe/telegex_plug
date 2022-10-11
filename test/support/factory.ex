defmodule Telegex.Plug.Factory do
  @moduledoc false

  defmodule Message do
    @moduledoc false

    defstruct [:text]

    @type t :: %__MODULE__{
            text: String.t()
          }
  end

  defmodule CallbackQuery do
    @moduledoc false

    defstruct [:data]

    @type t :: %__MODULE__{
            data: String.t()
          }
  end

  defmodule Update do
    @moduledoc false

    @enforce_keys [:update_id]
    defstruct [:update_id, :callback_query, :message, :edited_message]

    @type t :: %__MODULE__{
            update_id: integer,
            callback_query: CallbackQuery.t(),
            message: Message.t(),
            edited_message: Message.t()
          }
  end

  def build_message_update(text) do
    %Update{
      update_id: 1,
      message: %Message{text: text}
    }
  end

  def build_edited_message_update(text) do
    %Update{
      update_id: 1,
      edited_message: %Message{text: text}
    }
  end
end
