# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :d3_ex_demo,
  generators: [timestamp_type: :utc_datetime]

# Configure the endpoint
config :d3_ex_demo, D3ExDemoWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: D3ExDemoWeb.ErrorHTML, json: D3ExDemoWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: D3ExDemo.PubSub,
  live_view: [signing_salt: "dXmIjQKg"]

# Configure esbuild. On NixOS the prebuilt binary downloaded into `_build/`
# can't run; if a system `esbuild` is available on PATH (e.g. via `nix
# develop`), use it. Falls back to the managed binary otherwise.
config :esbuild,
  version: "0.27.2",
  path: System.get_env("ESBUILD_BIN") || System.find_executable("esbuild"),
  d3_ex_demo: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind. Same NixOS escape hatch via `TAILWIND_BIN`.
config :tailwind,
  version: "4.2.4",
  path: System.get_env("TAILWIND_BIN") || System.find_executable("tailwindcss"),
  d3_ex_demo: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
