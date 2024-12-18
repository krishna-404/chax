This file is about CLI commands used in the process creating Chax. Please go through the commits one by one to see the changes.

Creating a new Phoenix Chat project

# CLI Commands:
## Initialize the project & create the database
```bash
mix phx.new chax
cd chax
mix ecto.create
```

## Generate schema for the database & migration
```bash
mix phx.gen.schema Chat.Room rooms name:string topic:text
mix ecto.migrate
```
Optional:
### Generate SQL dump of current database schema
```bash
mix ecto.dump
```

## Generate a new migration to add a unique index on the room name
```bash
mix phx.gen.migration create_unique_index_on_room_name
mix ecto.migrate
```
## Generate a phoenix auth for auth based on email and password
```bash
mix phx.gen.auth Accounts User users
```
When prompted for live-view based authentication, select `yes`.

```bash
mix deps.get
mix ecto.migrate
```

## Generate schema for chat messages
```bash
mix phx.gen.schema Chat.Message messages user_id:references:users room_id:references:rooms body:text
```

## Migrate the database
```bash
mix ecto.migrate
```

## Seed the database
```bash
mix run priv/repo/seeds.exs
```

## Generate a phoenix presence instance
```bash
mix phx.gen.presence
```

## Generate a room membership schema
```bash
mix phx.gen.schema Chat.RoomMembership room_memberships user_id:references:users room_id:references:rooms
mix ecto.migrate
```

## Generate a migration to add last_read_id to room_memberships
```bash
mix phx.gen.migration add_last_read_id_to_memberships
mix ecto.migrate
```

## Allow users to have usernames
```
mix ecto.gen.migration add_username_to_users
mix ecto.migrate
```

## Generate a migration to create replies
```bash
mix phx.gen.schema Chat.Reply replies \
 message_id:references:messages user_id:references:users body:text
mix ecto.migrate
```

## Generate migration allow users to add reactions to messages
```bash
mix phx.gen.schema Chat.Reaction reactions user_id:references:users \
    message_id:references:messages emoji:string
mix ecto.migrate
```