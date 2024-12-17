defmodule Chax.Chat do
  alias Chax.Accounts.User
  alias Chax.Chat.{Message, Room, RoomMembership}
  alias Chax.Repo

  import Ecto.Query

  @pubsub Chax.PubSub

  def change_message(message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end

  def create_message(room, attrs, user) do
    with {:ok, message} <-
      %Message{room: room, user: user}
      |> Message.changeset(attrs)
      |> Repo.insert() do
        Phoenix.PubSub.broadcast!(@pubsub, topic(room.id), {:new_message, message})
        {:ok, message}
      end
  end

  def change_room(room, attrs \\ %{}) do
    Room.changeset(room, attrs)
  end

  def create_room(attrs) do
    %Room{}
    |> Room.changeset(attrs)
    |> Repo.insert!()
  end

  def delete_message_by_id(id, %User{id: user_id}) do
    #message = %Message{user_id: ^user_id} = Repo.get!(Message, id)
    message = Repo.get!(Message, id)
    if message.user_id != user_id do
      raise "Not authorized"
    end
    Repo.delete(message)

    Phoenix.PubSub.broadcast!(@pubsub, topic(message.room_id), {:message_deleted, message})

    {:ok, message}
  end

  def get_first_room! do
    Repo.one!(Room |> order_by([asc: :name]) |> limit(1))
  end

  def get_room(id) do
    Repo.get!(Room, id)
  end

  def join_room!(room, user) do
    Repo.insert!(%RoomMembership{room: room, user: user})
  end

  def joined?(%Room{} = room, %User{} = user) do
    Repo.exists?(RoomMembership |> where([rm], rm.room_id == ^room.id and rm.user_id == ^user.id))
  end

  def list_messages_in_room(%Room{id: room_id}) do
    Message
    |> where([m], m.room_id == ^room_id)
    |> order_by([m], asc: :inserted_at, asc: :id)
    |> preload([:user])
    |> Repo.all()
  end

  def list_joined_rooms(%User{} = user) do
    user
    |> Repo.preload(:rooms)
    |> Map.fetch!(:rooms)
    |> Enum.sort_by(& &1.name)
  end

  def list_rooms do
    Repo.all(Room |> order_by([asc: :name]))
  end

  def list_rooms_with_joined(%User{} = user) do
    query =
      from r in Room,
        left_join: rm in RoomMembership,
        on: rm.room_id == r.id and rm.user_id == ^user.id,
        select: {r, not is_nil(rm.id)},
        order_by: [asc: :name]

    Repo.all(query)
  end

  def subscribe_to_room(room) do
    IO.inspect(room, label: "room")
    Phoenix.PubSub.subscribe(@pubsub, topic(room.id))
  end

  def unsubscribe_from_room(room) do
    Phoenix.PubSub.unsubscribe(@pubsub, topic(room.id))
  end

  defp topic(room_id), do: "chat_room:#{room_id}"

  def update_room(%Room{} = room, attrs) do
    room
    |> Room.changeset(attrs)
    |> Repo.update()
  end
end
