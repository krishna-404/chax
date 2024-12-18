defmodule Chax.Chat.Reaction do
  use Ecto.Schema
  import Ecto.Changeset

  alias Chax.Chat.Message
  alias Chax.Accounts.User

  schema "reactions" do
    field :emoji, :string
    belongs_to :user, User
    belongs_to :message, Message

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(reaction, attrs) do
    reaction
    |> cast(attrs, [:emoji])
    |> unique_constraint([:emoji, :user_id, :message_id])
    |> validate_required([:emoji])
  end
end
