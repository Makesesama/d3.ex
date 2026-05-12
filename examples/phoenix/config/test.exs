import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :d3_ex_demo, D3ExDemoWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "0z0R2sEDs1Ed1QsgoRJWxyNcqs30vzDseUuD88tn+eD5q+BX62lYsouq9zZ+lzDw",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
