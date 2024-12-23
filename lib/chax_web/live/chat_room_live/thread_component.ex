defmodule ChaxWeb.ChatRoomLive.ThreadComponent do
  use ChaxWeb, :live_component

  alias Chax.Chat
  alias Chax.Chat.Reply

  import ChaxWeb.ChatComponents

  def render(assigns) do
    ~H"""
    <div
      class={[
        "flex flex-col bg-slate-100",
        "fixed sm:static sm:w-96",
        "border-l border-slate-300",
        "z-50 sm:z-0",
        "transform transition-transform duration-300 ease-in-out sm:transform-none",
        "inset-0 sm:inset-auto",
        "translate-x-0"
      ]}
      id="thread-component"
      phx-hook="Thread"
    >
      <div class="flex items-center flex-shrink-0 h-16 border-b border-slate-300 px-4 bg-white">
        <button
          class="sm:hidden flex items-center justify-center w-8 h-8 -ml-2 rounded-full hover:bg-gray-100"
          phx-click="close-thread"
        >
          <.icon name="hero-arrow-left" class="w-5 h-5" />
        </button>
        <div class="flex flex-col ml-2">
          <h2 class="text-base font-semibold leading-none">Thread</h2>
          <span class="text-sm text-gray-600 mt-1">
            #<%= @room.name %>
          </span>
        </div>
        <button
          class="hidden sm:flex items-center justify-center w-6 h-6 rounded hover:bg-gray-300 ml-auto"
          phx-click="close-thread"
        >
          <.icon name="hero-x-mark" class="w-5 h-5" />
        </button>
      </div>
      <div id="thread-message-with-replies" class="flex flex-col flex-grow overflow-y-auto">
        <div class="border-b border-slate-300">
          <.message
            message={@message}
            dom_id="thread-message"
            current_user={@current_user}
            in_thread?
            timezone={@timezone}
          />
        </div>
        <div id="thread-replies" phx-update="stream">
          <.message
            :for={{dom_id, reply} <- @streams.replies}
            current_user={@current_user}
            dom_id={dom_id}
            message={reply}
            in_thread?
            timezone={@timezone}
          />
        </div>
      </div>
      <div class="bg-slate-100 px-4 pt-3 mt-auto">
        <div :if={@joined?} class="h-12 pb-4">
          <.form
            class="flex items-center border-2 border-slate-300 rounded-sm p-1"
            for={@form}
            id="new-reply-form"
            phx-change="validate-reply"
            phx-submit="submit-reply"
            phx-target={@myself}
          >
            <textarea
              class="flex-grow text-sm px-3 border-l border-slate-300 mx-1 resize-none bg-slate-50"
              cols=""
              id="thread-message-textarea"
              name={@form[:body].name}
              phx-debounce
              phx-hook="ChatMessageTextarea"
              placeholder="Reply…"
              rows="1"
            ><%= Phoenix.HTML.Form.normalize_value("textarea", @form[:body].value) %></textarea>
            <button class="flex-shrink flex items-center justify-center h-6 w-6 rounded hover:bg-slate-200">
              <.icon name="hero-paper-airplane" class="h-4 w-4" />
            </button>
          </.form>
        </div>
      </div>
    </div>
    """
  end

  def update(assigns, socket) do
    socket
    |> assign_form(Chat.change_reply(%Reply{}))
    |> stream(:replies, assigns.message.replies, reset: true)
    |> assign(assigns)
    |> ok()
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset))
  end

  def handle_event("submit-reply", %{"reply" => message_params}, socket) do
    %{current_user: current_user, room: room} = socket.assigns

    if !Chat.joined?(room, current_user) do
      raise "not allowed"
    end

    case Chat.create_reply(
           socket.assigns.message,
           message_params,
           socket.assigns.current_user
         ) do
      {:ok, _message} ->
        assign_form(socket, Chat.change_reply(%Reply{}))

      {:error, changeset} ->
        assign_form(socket, changeset)
    end
    |> noreply()
  end

  def handle_event("validate-reply", %{"reply" => message_params}, socket) do
    changeset = Chat.change_reply(%Reply{}, message_params)

    {:noreply, assign_form(socket, changeset)}
  end
end
