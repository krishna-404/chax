defmodule ChaxWeb.ChatRoomLive do
  use ChaxWeb, :live_view

  alias Chax.Repo
  alias Chax.Chat.Room

  def render(assigns) do
    ~H"""
      <div class="flex flex-col flex-grow shadow-lg">
      <div class="flex justify-between items-center flex-shrink-0 h-16 bg-white border-b border-slate-300 px-4">
        <div class="flex flex-col gap-1.5">
          <h1 class="text-sm font-bold leading-none">
            #{@room.name}
          </h1>
          <div class="text-xs leading-none h-3.5" phx-click="toggle-topic">
            {@hide_topic && "Placeholder topic" || @room.topic}
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    IO.puts("mounting")
    if connected?(socket) do
      IO.puts("mounting (connected)")
    else
      IO.puts("mounting (not connected)")
    end
    room = Room |> Repo.all() |> List.first()

    socket =
      socket
      |> assign(:room, room)
      |> assign(:hide_topic, true)

    {:ok, socket}
  end

  def handle_event("toggle-topic", _params, socket) do
    {:noreply, socket |> update(:hide_topic, &(!&1))}
  end
end
