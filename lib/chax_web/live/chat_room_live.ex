defmodule ChaxWeb.ChatRoomLive do
  use ChaxWeb, :live_view

  def render(assigns) do
    ~H"""
      <div>Welcome to the chat room</div>
    """
  end
end
