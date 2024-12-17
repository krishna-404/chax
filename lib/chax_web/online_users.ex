defmodule ChaxWeb.OnlineUsers do
  alias ChaxWeb.Presence

  @topic "online_users"

  def list() do
    @topic
    |> Presence.list()
    |> Enum.into(
      %{},
      fn {id, %{metas: metas}} -> {String.to_integer(id), length(metas)} end
    )
  end

  def online?(online_users, user_id) do
    Map.get(online_users, user_id, 0) > 0
  end

  def subscribe() do
    Phoenix.PubSub.subscribe(Chax.PubSub, @topic)
  end

  def track(pid, user) do
    {:ok, _ref} = Presence.track(pid, @topic, user.id, %{})
    :ok
  end

  def update(online_users, %{joins: joins, leaves: leaves}) do
    online_users
    |> process_updates(joins, &Kernel.+/2)
    |> process_updates(leaves, &Kernel.-/2)
  end

  defp process_updates(online_users, updates, operation) do
    Enum.reduce(updates, online_users, fn {id, %{metas: metas}}, acc ->
      Map.update(
        acc,
        String.to_integer(id),
        length(metas),
        &operation.(&1, length(metas))
      )
    end)
  end
end
