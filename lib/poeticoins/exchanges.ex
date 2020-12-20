defmodule Poeticoins.Exchanges do
  alias Poeticoins.{Product, Trade}

  @clients [
    Poeticoins.Exchanges.CoinbaseClient,
    Poeticoins.Exchanges.BitstampClient
  ]
  @available_products (for client <- @clients, pair <- client.available_currency_pairs() do
                         Product.new(client.exchange_name(), pair)
                       end)

  def clients, do: @clients

  @spec available_products() :: [Product.t()]
  def available_products(), do: @available_products

  @spec subscribe(Product.t()) :: :ok | {:error, term()}
  def subscribe(product) do
    Phoenix.PubSub.subscribe(Poeticoins.PubSub, to_string(product))
  end

  @spec unsubscribe(Product.t()) :: :ok | {:error, term()}
  def unsubscribe(product) do
    Phoenix.PubSub.unsubscribe(Poeticoins.PubSub, to_string(product))
  end

  @spec broadcast(Trade.t()) :: :ok | {:error, term()}
  def broadcast(trade) do
    topic = to_string(trade.product)
    Phoenix.PubSub.broadcast(Poeticoins.PubSub, topic, {:new_trade, trade})
  end
end
