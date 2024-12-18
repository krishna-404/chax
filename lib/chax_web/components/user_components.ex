defmodule ChaxWeb.UserComponents do
  use ChaxWeb, :html

  alias Chax.Accounts.User

  attr :user, User
  attr :rest, :global, include: [:action] # To force user_avatar/1 to treat action like a global attribute, pass an :include option to attr/3:
  def user_avatar(assigns) do
    ~H"""
    <img
      src={user_avatar_path(@user)}
      {@rest}
    >
    """
  end

  defp user_avatar_path(user) do
    if user.avatar_path do
      ~p"/uploads/#{user.avatar_path}"
    else
      ~p"/images/one_ring.jpg"
    end
  end
end
