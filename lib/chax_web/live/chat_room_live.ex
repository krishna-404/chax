defmodule ChaxWeb.ChatRoomLive do
  use ChaxWeb, :live_view

  alias Chax.Repo
  alias Chax.Chat.Room

  def render(assigns) do
    ~H"""
      <div class="flex flex-col flex-shrink-0 w-64 bg-slate-100">
        <div class="flex justify-between items-center flex-shrink-0 h-16 border-b border-slate-300 px-4">
          <div class="flex flex-col gap-1.5">
            <h1 class="text-lg font-bold text-gray-800">
              Slax
            </h1>
          </div>
        </div>
        <div class="mt-4 overflow-auto">
          <div class="flex items-center h-8 px-3 group">
            <span class="ml-2 leading-none font-medium text-sm">Rooms</span>
          </div>
          <div id="rooms-list">
            <%!-- A function component is any function that receives an assigns map as an argument and returns a rendered struct built with the ~H sigil --%>
            <.room_link :for={room <- @rooms} room={room} active={room.id == @room.id} />
          </div>
        </div>
      </div>
      <div class="flex flex-col flex-grow shadow-lg">
      <div class="flex justify-between items-center flex-shrink-0 h-16 bg-white border-b border-slate-300 px-4">
        <div class="flex flex-col gap-1.5">
          <h1 class="text-sm font-bold leading-none">
            #{@room.name}
          </h1>
          <div class="text-xs leading-none h-3.5" phx-click="toggle-topic">
            {(@hide_topic && "Placeholder topic") || @room.topic}
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :active, :boolean, required: true
  attr :room, Room, required: true
  defp room_link(assigns) do
    ~H"""
    <.link
      class={[
        "flex items-center h-8 text-sm pl-8 pr-3",
        (@active && "bg-slate-300") || "hover:bg-slate-300"
      ]}
      href={~p"/rooms/#{@room}"}
    >
      <.icon name="hero-hashtag" class="h-4 w-4" />
      <span class={["ml-2 leading-none", @active && "font-bold"]}>
        <%= @room.name %>
      </span>
    </.link>
    """
  end

  def mount(params, _session, socket) do
    IO.puts("mounting")
    if connected?(socket) do
      IO.puts("mounting (connected)")
    else
      IO.puts("mounting (not connected)")
    end
    rooms = Room |> Repo.all()
    room = case Map.fetch(params, "id") do
      {:ok, id} ->
        Repo.get!(Room, id)
      :error ->
        rooms |> List.first()
    end

    socket =
      socket
      |> assign(:rooms, rooms)
      |> assign(:room, room)
      |> assign(:hide_topic, true)

    {:ok, socket}
  end

  def handle_event("toggle-topic", _params, socket) do
    {:noreply, socket |> update(:hide_topic, &(!&1))}
  end
end
