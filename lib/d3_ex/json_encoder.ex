defmodule D3Ex.JSONEncoder do
  @moduledoc """
  JSON encoding abstraction.

  D3Ex needs to encode data, config, and event maps into JSON for `data-*`
  attributes the JS hook reads. By default it uses Elixir's stdlib `JSON`
  module (1.18+), which keeps the library dependency-free beyond
  `phoenix_live_view`.

  To swap in Jason, Poison, or any other encoder, point the
  `:json_encoder` key at a module exposing `encode!/1`:

      config :d3_ex, json_encoder: Jason

  Jason and Poison both expose `encode!/1` already, so no adapter is needed.

  ## Custom encoders

  For a typed contract, implement this behaviour:

      defmodule MyApp.JSONEncoder do
        @behaviour D3Ex.JSONEncoder

        @impl true
        def encode!(term), do: # ...
      end

      # config/config.exs
      config :d3_ex, json_encoder: MyApp.JSONEncoder
  """

  @callback encode!(term()) :: iodata()

  @doc "Encode `term` to JSON using the configured encoder."
  def encode!(term), do: impl().encode!(term)

  defp impl do
    Application.get_env(:d3_ex, :json_encoder, D3Ex.JSONEncoder.Default)
  end
end

defmodule D3Ex.JSONEncoder.Default do
  @moduledoc """
  Default JSON encoder backed by Elixir's stdlib `JSON` module (1.18+).
  """

  @behaviour D3Ex.JSONEncoder

  @impl true
  def encode!(term), do: JSON.encode!(term)
end
