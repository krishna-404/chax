defmodule Chax.Chat do
  alias Chax.Chat.Room
  alias Chax.Repo
  import Ecto.Query

  def change_room(room, attrs \\ %{}) do
    Room.changeset(room, attrs)
  end

  def create_room(attrs) do
    %Room{}
    |> Room.changeset(attrs)
    |> Repo.insert!()
  end

  def get_first_room! do
    Repo.one!(Room |> order_by([asc: :name]) |> limit(1))
  end

  def get_room(id) do
    Repo.get!(Room, id)
  end

  def list_rooms do
    Repo.all(Room |> order_by([asc: :name]))
  end

  def update_room(%Room{} = room, attrs) do
    room
    |> Room.changeset(attrs)
    |> Repo.update!()
  end
end
