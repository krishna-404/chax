# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Chax.Repo.insert!(%Chax.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Chax.Accounts
alias Chax.Chat.Room
alias Chax.Chat.Message
alias Chax.Repo
alias Chax.Accounts.User

Repo.delete_all(Message)
Repo.delete_all(Room)
Repo.delete_all(User)

names = ["Alice", "Bob", "Charlie", "Diana", "Eve", "Mallory", "Trent", "Victor", "Wendy", "Xavier", "Yvonne", "Zoe"]

pw = "password123456"

for name <- names do
  email = (name |> String.downcase()) <> "@example.com"
  user = Accounts.register_user(%{email: email, password: pw, password_confirmation: pw})
end

users = Repo.all(User)

# Randomly create 6 rooms
rooms = [
  %{name: "general", topic: "General chat"},
  %{name: "random", topic: "Random chat"},
  %{name: "programming", topic: "Programming chat"},
  %{name: "gaming", topic: "Gaming chat"},
  %{name: "music", topic: "Music chat"},
  %{name: "movies", topic: "Movies chat"}
]
|> Enum.map(fn attrs ->
    %Room{}
    |> Room.changeset(attrs)
    |> Repo.insert!()
  end)

# Randomly assign 10 messages to each room by randomly selecting users

# 10 messages text which can be assigned later
message_texts = [
  "Hello everyone!",
  "How are you all doing?",
  "What's everyone's favorite programming language?",
  "What's your favorite game?",
  "What's your favorite song?",
  "What's your favorite movie?",
  "What's everyone's favorite color?",
  "What's everyone's favorite food?",
  "What's everyone's favorite animal?",
  "What's everyone's favorite book?"
]

for room <- rooms do
  for _ <- 1..10 do
    message_text = Enum.random(message_texts)
    user = Enum.random(users)
    Repo.insert!(%Message{body: message_text, user_id: user.id, user: user, room_id: room.id, room: room})
  end
end
