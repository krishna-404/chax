defmodule ChaxWeb.ChatRoomLive do
  use ChaxWeb, :live_view

  alias Chax.Chat
  alias Chax.Chat.{Message, Room}
  alias Chax.Accounts
  alias Chax.Accounts.User
  alias ChaxWeb.ChatRoomLive.ThreadComponent
  alias ChaxWeb.OnlineUsers

  import ChaxWeb.ChatComponents
  import ChaxWeb.UserComponents

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
            <.toggler on_click={toggle_rooms()} dom_id="rooms-toggler" text="Rooms" />
          </div>
          <div id="rooms-list">
            <%!-- A function component is any function that receives an assigns map as an argument and returns a rendered struct built with the ~H sigil --%>
            <.room_link
            :for={{room, unread_count} <- @rooms}
            room={room}
            active={room.id == @room.id}
            unread_count={unread_count}
          />
            <button class="group relative flex items-center h-8 text-sm pl-8 pr-3 hover:bg-slate-300 cursor-pointer w-full">
              <.icon name="hero-plus" class="h-4 w-4 relative top-px" />
              <span class="ml-2 leading-none">Add rooms</span>
              <div class="hidden group-focus:block cursor-default absolute top-8 right-2 bg-white border-slate-200 border py-3 rounded-lg">
                <div class="w-full text-left">
                  <div class="hover:bg-sky-600">
                    <div
                      class="cursor-pointer whitespace-nowrap text-gray-800 hover:text-white px-6 py-1 block"
                      phx-click={JS.navigate(~p"/rooms/#{@room}/new")}
                    >
                      Create a new room
                    </div>
                  </div>
                  <div class="hover:bg-sky-600">
                    <div
                      phx-click={JS.navigate(~p"/rooms")}
                      class="cursor-pointer whitespace-nowrap text-gray-800 hover:text-white px-6 py-1"
                    >
                      Browse rooms
                    </div>
                  </div>
                </div>
              </div>
            </button>
          </div>
          <div class="mt-4">
            <div class="flex items-center h-8 px-3 group">
              <div class="flex items-center flex-grow focus:outline-none">
                <.toggler on_click={toggle_users()} dom_id="users-toggler" text="Users" />
              </div>
            </div>
            <div id="users-list">
              <.user
                :for={user <- @users}
                user={user}
                online={OnlineUsers.online?(@online_users, user.id)}
              />
            </div>
          </div>
        </div>
      </div>
      <div class="flex flex-col flex-grow shadow-lg">
        <div class="flex justify-between items-center flex-shrink-0 h-16 bg-white border-b border-slate-300 px-4">
          <div class="flex flex-col gap-1.5">
            <h1 class="text-sm font-bold leading-none">
              #{@room.name}

              <.link
                :if={@joined?}
                class="font-normal text-xs text-blue-600 hover:text-blue-700"
                navigate={~p"/rooms/#{@room}/edit"}
              >
                Edit
              </.link>
            </h1>
            <div class="text-xs leading-none h-3.5" phx-click="toggle-topic">
              {(@hide_topic? && "Show topic") || @room.topic}
            </div>
          </div>
          <ul class="relative z-10 flex items-center gap-4 px-4 sm:px-6 lg:px-8 justify-end">
            <li class="text-[0.8125rem] leading-6 text-zinc-900">
              <div class="text-sm leading-10">
              <.link
                class="flex gap-4 items-center"
                phx-click="show-profile"
                phx-value-user-id={@current_user.id}
              >
                <.user_avatar user={@current_user} class="h-8 w-8 rounded" />
                <span class="hover:underline"><%= @current_user.username %></span>
              </.link>
            </div>
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
          </ul>
        </div>
        <div :if={@message_cursor} class="flex justify-around my-2">
          <button
            id="load-more-button"
            phx-click="load-more-messages"
            class="border border-green-200 bg-green-50 py-1 px-3 rounded"
          >
            Load more
          </button>
        </div>
        <div
          id="room-messages"
          class="flex flex-col flex-grow overflow-auto"
          phx-hook="RoomMessages"
          phx-update="stream"
        >
          <%= for {dom_id, message} <- @streams.messages do %>
            <%= case message do %>
              <% :unread_marker -> %>
                <div id={dom_id} class="w-full flex text-red-500 items-center gap-3 pr-5">
                  <div class="w-full h-px grow bg-red-500"></div>
                  <div class="text-sm">New</div>
                </div>
              <% %Message{} -> %>
                <.message
                  current_user={@current_user}
                  dom_id={dom_id}
                  message={message}
                  timezone={@timezone}
                />
              <% %Date{} -> %>
                <div id={dom_id} class="flex flex-col items-center mt-2">
                  <hr class="w-full" />
                  <span class="flex items-center justify-center -mt-3 bg-white h-6 px-3 rounded-full border text-xs font-semibold mx-auto">
                    <%= format_date(message) %>
                  </span>
                </div>
            <% end %>
          <% end %>
        </div>
     <div :if={@joined?} class="h-12 bg-white px-4 pb-4">
        <.form
          id="new-message-form"
          for={@new_message_form}
          phx-change="validate-message"
          phx-submit="submit-message"
          class="flex items-center border-2 border-slate-300 rounded-sm p-1"
        >
          <textarea
            class="flex-grow text-sm px-3 border-l border-slate-300 mx-1 resize-none"
            cols=""
            id="chat-message-textarea"
            name={@new_message_form[:body].name}
            placeholder={"Message ##{@room.name}"}
            phx-debounce
            phx-hook="ChatMessageTextarea"
            rows="1"
          >
            <%= Phoenix.HTML.Form.normalize_value("textarea", @new_message_form[:body].value) %>
          </textarea>
          <button class="flex-shrink flex items-center justify-center h-6 w-6 rounded hover:bg-slate-200">
            <.icon name="hero-paper-airplane" class="h-4 w-4" />
          </button>
        </.form>
      </div>
      <div
        :if={!@joined?}
        class="flex justify-around mx-5 mb-5 p-6 bg-slate-100 border-slate-300 border rounded-lg"
      >
        <div class="max-w-3-xl text-center">
          <div class="mb-4">
            <h1 class="text-xl font-semibold">#<%= @room.name %></h1>
            <p :if={@room.topic} class="text-sm mt-1 text-gray-600"><%= @room.topic %></p>
          </div>
          <div class="flex items-center justify-around">
            <button
              phx-click="join-room"
              class="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-600 focus:outline-none focus:ring-2 focus:ring-green-500"
            >
              Join Room
            </button>
          </div>
          <div class="mt-4">
            <.link
              navigate={~p"/rooms"}
              href="#"
              class="text-sm text-slate-500 underline hover:text-slate-600"
            >
              Back to All Rooms
            </.link>
          </div>
        </div>
      </div>
    </div>

    <%= if assigns[:profile] do %>
      <.live_component
        id="profile"
        module={ChaxWeb.ChatRoomLive.ProfileComponent}
        user={@profile}
        current_user={@current_user}
      />
    <% end %>

    <%= if assigns[:thread] do %>
      <.live_component
        current_user={@current_user}
        id="thread"
        joined?={@joined?}
        module={ThreadComponent}
        message={@thread}
        room={@room}
        timezone={@timezone}
      />
    <% end %>

    <.modal id="new-room-modal" show={@live_action == :new} on_cancel={JS.navigate(~p"/rooms/#{@room}")}>
      <.header>New chat room</.header>
      <.live_component
        module={ChaxWeb.ChatRoomLive.FormComponent}
        id="new-room-form-component"
        current_user={@current_user}
      />
    </.modal>
    """
  end

  defp format_date(%Date{} = date) do
    today = Date.utc_today()

    case Date.diff(today, date) do
      0 ->
        "Today"

      1 ->
        "Yesterday"

      _ ->
        format_str = "%A, %B %e#{ordinal(date.day)}#{if today.year != date.year, do: " %Y"}"
        Timex.format!(date, format_str, :strftime)
    end
  end

  defp ordinal(day) do
    cond do
      rem(day, 10) == 1 and day != 11 -> "st"
      rem(day, 10) == 2 and day != 12 -> "nd"
      rem(day, 10) == 3 and day != 13 -> "rd"
      true -> "th"
    end
  end

  attr :dom_id, :string, required: true
  attr :text, :string, required: true
  attr :on_click, :fun, required: true
  defp toggler(assigns) do
    ~H"""
    <button id={@dom_id} phx-click={@on_click} class="flex items-center flex-grow focus:outline-none">
      <.icon id={@dom_id <> "-chevron-down"} name="hero-chevron-down" class="h-4 w-4" />
      <.icon
        id={@dom_id <> "-chevron-right"}
        name="hero-chevron-right"
        class="h-4 w-4"
        style="display:none;"
      />
      <span class="ml-2 leading-none font-medium text-sm">
        <%= @text %>
      </span>
    </button>
    """
  end

  attr :count, :integer, required: true
  defp unread_message_counter(assigns) do
    ~H"""
    <span
      :if={@count > 0}
      class="flex items-center justify-center bg-blue-500 rounded-full font-medium h-5 px-2 ml-auto text-xs text-white"
    >
      <%= @count %>
    </span>
    """
  end

  attr :user, User, required: true
  attr :online, :boolean, default: false
  defp user(assigns) do
    ~H"""
      <.link class="flex items-center h-8 hover:bg-gray-300 text-sm pl-8 pr-3" href="#">
        <div class="flex justify-center w-4">
          <%= if @online do %>
            <span class="w-2 h-2 rounded-full bg-blue-500"></span>
          <% else %>
            <span class="w-2 h-2 rounded-full border-2 border-gray-500"></span>
          <% end %>
        </div>
        <span class="ml-2 leading-none"><%= @user.username %></span>
      </.link>
    """
  end

  attr :active, :boolean, required: true
  attr :room, Room, required: true
  attr :unread_count, :integer, required: true
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
      <.unread_message_counter count={@unread_count} />
    </.link>
    """
  end

  # Mount is not called when patch is used in <.link>
  def mount(_params, _session, socket) do
    rooms = Chat.list_joined_rooms_with_unread_count(socket.assigns.current_user)
    users = Accounts.list_users()

    timezone = get_connect_params(socket)["timezone"]

    if connected?(socket) do
      OnlineUsers.track(self(), socket.assigns.current_user)
    end

    OnlineUsers.subscribe()

    Accounts.subscribe_to_user_avatars()

    Enum.each(rooms, fn {chat, _} -> Chat.subscribe_to_room(chat) end)

    socket
    |> assign(:rooms, rooms)
    |> assign(:timezone, timezone)
    |> assign(:users, users)
    |> assign(:online_users, OnlineUsers.list())
    |> stream_configure(:messages,
      dom_id: fn
        %Message{id: id} -> "message-#{id}"
        :unread_marker -> "messages-unread-marker"
        %Date{} = date -> to_string(date)
      end
    )
    |> ok()
  end

  @spec handle_params(map(), any(), map()) :: {:noreply, map()}
  def handle_params(params, _session, socket) do
    room = case Map.fetch(params, "id") do
      {:ok, id} ->
        Chat.get_room!(id)
      :error ->
        Chat.get_first_room!()
    end

    page = Chat.list_messages_in_room(room)

    IO.inspect(room, label: "room")
    current_user = socket.assigns.current_user

    last_read_id = Chat.get_last_read_id(room, current_user)

    Chat.update_last_read_id(room, current_user)

    socket
    |> assign(:room, room)
    |> assign(:last_read_id, last_read_id)
    |> assign(:hide_topic?, false)
    |> assign(:joined?, Chat.joined?(room, current_user))
    |> assign(:page_title, "#" <> room.name)
    |> stream(:messages, [], reset: true)
    |> stream_message_page(page)
      |> assign_message_form(Chat.change_message(%Message{})) # To reset the message form on room change
      |> push_event("scroll_messages_to_bottom", %{})
      |> update(:rooms, fn rooms ->
        room_id = room.id

        Enum.map(rooms, fn
          {%Room{id: ^room_id} = room, _} -> {room, 0}
          other -> other
        end)
      end)
      |> noreply()
  end

  defp stream_message_page(socket, %Paginator.Page{} = page) do
    last_read_id = socket.assigns.last_read_id

    messages =
      page.entries
      |> Enum.reverse()
      |> insert_date_dividers(socket.assigns.timezone)
      |> maybe_insert_unread_marker(last_read_id)
      |> Enum.reverse()

    socket
    |> stream(:messages, messages, at: 0)
    |> assign(:message_cursor, page.metadata.after)
  end

  defp insert_date_dividers(messages, nil), do: messages

  defp insert_date_dividers(messages, timezone) do
    messages
    |> Enum.group_by(fn message ->
      message.inserted_at
      |> DateTime.shift_zone!(timezone)
      |> DateTime.to_date()
    end)
    |> Enum.sort_by(fn {date, _msgs} -> date end, &(Date.compare(&1, &2) != :gt))
    |> Enum.flat_map(fn {date, messages} -> [date | messages] end)
  end

  defp assign_message_form(socket, changeset) do
    assign(socket, :new_message_form, to_form(changeset))
  end

  defp maybe_insert_unread_marker(messages, nil), do: messages

  defp maybe_insert_unread_marker(messages, last_read_id) do
    {read, unread} =
      Enum.split_while(messages, fn
        %Message{} = message -> message.id <= last_read_id
        _ -> true
      end)

    if unread == [] do
      read
    else
      read ++ [:unread_marker | unread]
    end
  end

  def handle_event("close-profile", _, socket) do
    {:noreply, assign(socket, :profile, nil)}
  end

  def handle_event("show-profile", %{"user-id" => user_id}, socket) do
    user = Accounts.get_user!(user_id)
    {:noreply, assign(socket, profile: user, thread: nil)}
  end

  def handle_event("toggle-topic", _params, socket) do
    socket |> update(:hide_topic?, &(!&1)) |> noreply()
  end

  def handle_event("validate-message", %{"message" => message_params}, socket) do
    changeset = Chat.change_message(%Message{}, message_params)
    socket |> assign_message_form(changeset) |> noreply()
  end

  def handle_event("load-more-messages", _, socket) do
    page =
      Chat.list_messages_in_room(
        socket.assigns.room,
        after: socket.assigns.message_cursor
      )

    socket
    |> stream_message_page(page)
    |> noreply()
  end

  def handle_event("submit-message", %{"message" => message_params}, socket) do
    %{current_user: current_user, room: room} = socket.assigns


    socket =
      if Chat.joined?(room, current_user) do
        case Chat.create_message(room, message_params, current_user) do
          {:ok, _message} ->
            socket |> assign_message_form(Chat.change_message(%Message{}))
          {:error, changeset} ->
            socket |> assign_message_form(changeset)
        end
      else
        socket
      end

    socket |> noreply()
  end

  def handle_event("delete-message", %{"id" => id, "type" => "Message"}, socket) do
    Chat.delete_message_by_id(id, socket.assigns.current_user)
    socket |> noreply()
  end

  def handle_event("delete-message", %{"id" => id, "type" => "Reply"}, socket) do
    Chat.delete_reply_by_id(id, socket.assigns.current_user)

    {:noreply, socket}
  end

  def handle_event("join-room", _, socket) do
    current_user = socket.assigns.current_user
    room = socket.assigns.room

    Chat.join_room!(room, current_user)
    Chat.subscribe_to_room(room)

    socket = assign(socket, joined?: true, rooms: Chat.list_joined_rooms_with_unread_count(current_user))

    socket |> noreply()
  end

  def handle_event("close-thread", _, socket) do
    {:noreply, assign(socket, :thread, nil)}
  end

  def handle_event("show-thread", %{"id" => message_id}, socket) do
    message = Chat.get_message!(message_id)

    socket |> assign(profile: nil, thread: message) |> noreply()
  end

  def handle_info({:deleted_reply, message}, socket) do
    socket
    |> refresh_message(message)
    |> noreply()
  end

  def handle_info({:new_reply, message}, socket) do
    if socket.assigns[:thread] && socket.assigns.thread.id == message.id do
      push_event(socket, "scroll_thread_to_bottom", %{})
    else
      socket
    end
    |> refresh_message(message)
    |> noreply()
  end

  def handle_info({:new_message, message}, socket) do
    room = socket.assigns.room

    socket =
      cond do
        message.room_id == room.id ->
          Chat.update_last_read_id(room, socket.assigns.current_user)

        socket
        |> stream_insert(:messages, message)
        |> push_event("scroll_messages_to_bottom", %{})

        message.user_id != socket.assigns.current_user.id ->
          update(socket, :rooms, fn rooms ->
            Enum.map(rooms, fn
              {%Room{id: id} = room, count} when id == message.room_id -> {room, count + 1}
              other -> other
            end)
          end)

        true ->
          socket
      end


    socket |> noreply()
  end

  def handle_info({:message_deleted, message}, socket) do
    socket |> stream_delete(:messages, message) |> noreply()
  end

  def handle_info(%{event: "presence_diff", payload: diff}, socket) do
    online_users = OnlineUsers.update(socket.assigns.online_users, diff)
    socket |> assign(:online_users, online_users) |> noreply()
  end

  def handle_info({:updated_avatar, user}, socket) do
    socket
    |> maybe_update_profile(user)
    |> maybe_update_current_user(user)
    |> push_event("update_avatar", %{user_id: user.id, avatar_path: user.avatar_path})
    |> noreply()
  end

  defp refresh_message(socket, message) do
    if message.room_id == socket.assigns.room.id do
      socket = stream_insert(socket, :messages, message)

      if socket.assigns[:thread] && socket.assigns.thread.id == message.id do
        assign(socket, :thread, message)
      else
        socket
      end
    else
      socket
    end
  end

  defp toggle_rooms() do
    JS.toggle(to: "#rooms-toggler-chevron-down")
    |> JS.toggle(to: "#rooms-toggler-chevron-right")
    |> JS.toggle(to: "#rooms-list")
  end

  defp toggle_users() do
    JS.toggle(to: "#users-toggler-chevron-down")
    |> JS.toggle(to: "#users-toggler-chevron-right")
    |> JS.toggle(to: "#users-list")
  end

  defp maybe_update_current_user(socket, user) do
    if socket.assigns.current_user.id == user.id do
      assign(socket, :current_user, user)
    else
      socket
    end
  end

  defp maybe_update_profile(socket, user) do
    if socket.assigns[:profile] && socket.assigns.profile.id == user.id do
      assign(socket, :profile, user)
    else
      socket
    end
  end
end
