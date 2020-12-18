defmodule Poeticoins.Exchanges.CoinbaseClient do
  alias Poeticoins.{Trade, Product}
  alias Poeticoins.Exchanges.Client
  require Client

  Client.defclient(
    exchange_name: "coinbase",
    host: 'ws-feed.pro.coinbase.com',
    currency_pairs: [btc: :usd, eth: :usd, ltc: :usd]
  )

  @impl true
  def handle_ws_message(%{"type" => "ticker"} = msg, state) do
    trade = message_to_trade(msg) |> IO.inspect(label: "trade")

    {:noreply, state}
  end

  def handle_ws_message(msg, state) do
    IO.inspect(msg, label: "unhandled message")
    {:noreply, state}
  end

  @impl true
  def subscription_frames(currency_pairs) do
    currency_pairs = Enum.map(currency_pairs, &currency_encoder/1)
    msg =
      %{
        "type" => "subscribe",
        "product_ids" => currency_pairs,
        "channels" => ["ticker"]
      }
      |> Jason.encode!()

    [{:text, msg}]
  end

  @spec message_to_trade(map()) :: {:ok, Trade.t()} | {:error, any()}
  def message_to_trade(msg) do
    with :ok <- validate_required(msg, ~W(product_id time price last_size)),
         {:ok, traded_at, _} = DateTime.from_iso8601(msg["time"]) do
      currency_pair = currency_decoder(msg["product_id"])

      Trade.new(
        product: Product.new(exchange_name(), currency_pair),
        price: msg["price"],
        volume: msg["last_size"],
        traded_at: traded_at
      )
    else
      {:error, _reason} = error -> error
    end
  end

  def currency_encoder({k, v} = currency_pair) do
    String.upcase("#{k}-#{v}")
  end

  def currency_decoder(<<k::bytes-size(3)>> <> "-" <> v = currency_pair) do
    {to_lower_atom(k), to_lower_atom(v)}
  end

  defp to_lower_atom(str) do
    str
    |> String.downcase
    |> String.to_existing_atom
  end
end
