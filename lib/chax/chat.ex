defmodule Chax.Chat do
  alias Chax.Chat.Room
  alias Chax.Repo
  import Ecto.Query

  def get_first_room! do
    Repo.one!(Room |> order_by([asc: :name]) |> limit(1))
  end

  def get_room(id) do
    Repo.get!(Room, id)
  end

  def list_rooms do
    Repo.all(Room |> order_by([asc: :name]))
  end
end
