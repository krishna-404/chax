defmodule Chax.Chat do
  alias Chax.Chat.Room
  alias Chax.Repo

  def get_room(id) do
    Repo.get!(Room, id)
  end

  def list_rooms do
    Repo.all(Room)
  end
end
