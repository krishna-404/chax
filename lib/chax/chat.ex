defmodule Chax.Chat do
  alias Chax.Accounts.User
  alias Chax.Chat.{Message, Room, RoomMembership}
  alias Chax.Repo

  import Ecto.Changeset
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
    |> Repo.insert()
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

  def get_last_read_id(%Room{} = room, %User{} = user) do
    case get_membership(room, user) do
      %RoomMembership{} = membership ->
        membership.last_read_id
      nil ->
        nil
    end
  end

  def get_message!(id) do
    Message
    |> where([m], m.id == ^id)
    |> preload(:user)
    |> Repo.one!()
  end

  def get_room!(id) do
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

  def list_joined_rooms_with_unread_count(%User{} = user) do
    Room
    |> join(:inner, [r], rm in assoc(r, :memberships), on: rm.user_id == ^user.id)
    |> join(:left, [r, rm], m in assoc(r, :messages), on: m.id > rm.last_read_id)
    |> group_by([r], r.id)
    |> select([r, rm, m], {r, count(m.id)})
    |> order_by([r], asc: r.name)
    |> Repo.all()
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

  def toggle_room_membership(room, user) do
    case get_membership(room, user) do
      %RoomMembership{} = membership ->
        Repo.delete(membership)
      {room, false}

      nil ->
        join_room!(room, user)
      {room, true}
    end
  end

  defp get_membership(room, user) do
    Repo.get_by(RoomMembership, room_id: room.id, user_id: user.id)
  end

  def unsubscribe_from_room(room) do
    Phoenix.PubSub.unsubscribe(@pubsub, topic(room.id))
  end

  defp topic(room_id), do: "chat_room:#{room_id}"

  def update_last_read_id(room, user) do
    case get_membership(room, user) do
      %RoomMembership{} = membership ->
        id =
          Message
            |> where([m], m.room_id == ^room.id)
            |> select([m], max(m.id))
            |> Repo.one()

        membership
          |> change(%{last_read_id: id})
          |> Repo.update!()
      nil ->
        nil
    end
  end

  def update_room(%Room{} = room, attrs) do
    room
    |> Room.changeset(attrs)
    |> Repo.update()
  end
end
