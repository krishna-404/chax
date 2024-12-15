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

# Chax

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
