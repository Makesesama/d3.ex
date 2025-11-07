defmodule D3Ex.Components do
  @moduledoc """
  Base module for D3Ex components.

  Provides common functionality and utilities for all D3.js visualization components.
  """

  @doc """
  Generates a unique DOM ID for a component if not provided.
  """
  def ensure_id(assigns) do
    Map.put_new_lazy(assigns, :id, fn -> "d3ex-#{:erlang.unique_integer([:positive])}" end)
  end

  @doc """
  Encodes data to JSON for passing to JavaScript hooks.
  """
  def encode_data(data) do
    Jason.encode!(data)
  end

  @doc """
  Builds a configuration map for D3.js from component assigns.
  """
  def build_config(assigns, defaults) do
    assigns
    |> Map.take(Map.keys(defaults))
    |> Enum.reduce(defaults, fn {key, value}, acc ->
      if value != nil, do: Map.put(acc, key, value), else: acc
    end)
  end
end
