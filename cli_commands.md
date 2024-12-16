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
