defmodule Chax.Chat do
  alias Chax.Accounts.User
  alias Chax.Chat.{Message, Room}
  alias Chax.Repo
  import Ecto.Query

  def change_message(message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end

  def create_message(room, attrs, user) do
    %Message{room: room, user: user}
    |> Message.changeset(attrs)
    |> Repo.insert()
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
  end

  def get_first_room! do
    Repo.one!(Room |> order_by([asc: :name]) |> limit(1))
  end

  def get_room(id) do
    Repo.get!(Room, id)
  end

  def list_messages_in_room(%Room{id: room_id}) do
    Message
    |> where([m], m.room_id == ^room_id)
    |> order_by([m], asc: :inserted_at, asc: :id)
    |> preload([:user])
    |> Repo.all()
  end

  def list_rooms do
    Repo.all(Room |> order_by([asc: :name]))
  end

  def update_room(%Room{} = room, attrs) do
    room
    |> Room.changeset(attrs)
    |> Repo.update()
  end
end
