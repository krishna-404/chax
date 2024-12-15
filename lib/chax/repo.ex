defmodule Chax.Repo do
  use Ecto.Repo,
    otp_app: :chax,
    adapter: Ecto.Adapters.Postgres
end
