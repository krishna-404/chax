defmodule ChaxWeb.ChatRoomLive do
  use ChaxWeb, :live_view

  alias Chax.Chat
  alias Chax.Chat.{Message, Room}

  def render(assigns) do
    ~H"""
      <div class="flex flex-col flex-shrink-0 w-64 bg-slate-100">
        <div class="flex justify-between items-center flex-shrink-0 h-16 border-b border-slate-300 px-4">
          <div class="flex flex-col gap-1.5">
            <h1 class="text-lg font-bold text-gray-800">
              Chax
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

            <.link
              class="font-normal text-xs text-blue-600 hover:text-blue-700"
              navigate={~p"/rooms/#{@room}/edit"}
            >
              Edit
            </.link>
          </h1>
          <div class="text-xs leading-none h-3.5" phx-click="toggle-topic">
            {(@hide_topic && "Show topic") || @room.topic}
          </div>
        </div>
        <ul class="relative z-10 flex items-center gap-4 px-4 sm:px-6 lg:px-8 justify-end">
          <%= if @current_user do %>
            <li class="text-[0.8125rem] leading-6 text-zinc-900">
              {username(@current_user)}
            </li>
            <li>
              <.link
                href={~p"/users/settings"}
                class="text-[0.8125rem] leading-6 text-zinc-900 font-semibold hover:text-zinc-700"
              >
                Settings
              </.link>
            </li>
            <li>
              <.link
                href={~p"/users/log_out"}
                method="delete"
                class="text-[0.8125rem] leading-6 text-zinc-900 font-semibold hover:text-zinc-700"
              >
                Log out
              </.link>
            </li>
          <% else %>
            <li>
              <.link
                href={~p"/users/register"}
                class="text-[0.8125rem] leading-6 text-zinc-900 font-semibold hover:text-zinc-700"
              >
                Register
              </.link>
            </li>
            <li>
              <.link
                href={~p"/users/log_in"}
                class="text-[0.8125rem] leading-6 text-zinc-900 font-semibold hover:text-zinc-700"
              >
                Log in
              </.link>
            </li>
          <% end %>
        </ul>
      </div>
      <div class="flex flex-col flex-grow overflow-auto">
       <.message :for={message <- @messages} message={message} />
     </div>
    </div>
    """
  end

  attr :message, Message, required: true
  def message(assigns) do
    ~H"""
      <div class="relative flex px-4 py-3">
        <div class="h-10 w-10 rounded flex-shrink-0 bg-slate-300"></div>
        <div class="ml-2">
          <div class="-mt-1">
            <.link class="text-sm font-semibold hover:underline">
              <span>{username(@message.user)}</span>
            </.link>
            <p class="text-sm"><%= @message.body %></p>
          </div>
        </div>
      </div>
    """
  end

  defp username(user) do
    user.email |> String.split("@") |> List.first() |> String.capitalize()
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
      patch={~p"/rooms/#{@room}"}
    >
      <.icon name="hero-hashtag" class="h-4 w-4" />
      <span class={["ml-2 leading-none", @active && "font-bold"]}>
        <%= @room.name %>
      </span>
    </.link>
    """
  end

  # Mount is not called when patch is used in <.link>
  def mount(_params, _session, socket) do
    rooms = Chat.list_rooms()

    socket =
      socket
      |> assign(:rooms, rooms)

    {:ok, socket}
  end

  @spec handle_params(map(), any(), map()) :: {:noreply, map()}
  def handle_params(params, _session, socket) do
    room = case Map.fetch(params, "id") do
      {:ok, id} ->
        Chat.get_room(id)
      :error ->
        Chat.get_first_room!()
    end

    messages = Chat.list_messages_in_room(room)

    socket = socket
      |> assign(:room, room)
      |> assign(:hide_topic, false)
      |> assign(:page_title, "#" <> room.name)
      |> assign(:messages, messages)

    {:noreply, socket}
  end

  def handle_event("toggle-topic", _params, socket) do
    {:noreply, socket |> update(:hide_topic, &(!&1))}
  end
end
