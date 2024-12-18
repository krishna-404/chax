defmodule Chax.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset
  alias Chax.Accounts.User
  alias Chax.Chat.{Reply, Room}

  schema "messages" do
    field :body, :string
    belongs_to :user, User
    belongs_to :room, Room
    has_many :replies, Reply

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:body])
    |> validate_required([:body])
  end
end
