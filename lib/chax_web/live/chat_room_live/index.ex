defmodule ChaxWeb.ChatRoomLive.Index do
  use ChaxWeb, :live_view

  alias Chax.Chat

  def render(assigns) do
    ~H"""
      <main class="flex-1 p-6 max-w-4xl mx-auto">
        <div class="mb-4">
          <h1 class="text-xl font-semibold"><%= @page_title %></h1>
        </div>
        <div class="bg-slate-50 border rounded">
          <div id="rooms" class="divide-y" phx-update="stream">
            <div
              :for={{id, {room, joined?}} <- @streams.rooms}
              class="cursor-pointer p-4 flex justify-between items-center group first:rounded-t last:rounded-b"
              id={id}
              phx-click={JS.navigate(~p"/rooms/#{room}")}
            >
              <div>
                <div class="font-medium mb-1">
                  #<%= room.name %>
                  <span class="mx-1 text-gray-500 font-light text-sm opacity-0 group-hover:opacity-100">
                    View room
                  </span>
                </div>
                <div class="text-gray-500 text-sm">
                  <%= if joined? do %>
                    <span class="text-green-600 font-bold">✓ Joined</span>
                  <% end %>
                  <%= if joined? && room.topic do %>
                    <span class="mx-1">·</span>
                  <% end %>
                  <%= if room.topic do %>
                    <%= room.topic %>
                  <% end %>
                </div>
              </div>
              <button
                class="opacity-0 group-hover:opacity-100 bg-white hover:bg-gray-100 border border-gray-400 text-gray-700 px-3 py-1.5 w-24 rounded-sm font-bold"
                phx-click="toggle-room-membership"
                phx-value-id={room.id}
              >
                <%= if joined? do %>
                  Leave
                <% else %>
                  Join
                <% end %>
              </button>
            </div>
          </div>
        </div>
      </main>
    """
  end

  def mount(_params, _session, socket) do
    rooms = Chat.list_rooms_with_joined(socket.assigns.current_user)
    socket =
      socket
      |> assign(:page_title, "All Rooms")
      |> stream_configure(:rooms, dom_id: fn {room, _} -> "room-#{room.id}" end)
      |> stream(:rooms, rooms)

    {:ok, socket}
  end

  def handle_event("toggle-room-membership", %{"id" => id}, socket) do
    {room, joined?} =
      id
      |> Chat.get_room!()
      |> Chat.toggle_room_membership(socket.assigns.current_user)

    {:noreply, stream_insert(socket, :rooms, {room, joined?})}
  end
end
