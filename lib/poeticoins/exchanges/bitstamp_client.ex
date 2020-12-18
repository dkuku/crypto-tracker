defmodule Poeticoins.Exchanges.BitstampClient do
  alias Poeticoins.{Trade, Product}
  alias Poeticoins.Exchanges.Client
  require Client

  Client.defclient(
    exchange_name: "bitstamp",
    host: 'ws.bitstamp.net',
    currency_pairs: [btc: :usd, eth: :usd, ltc: :usd]
  )

  @impl true
  def handle_ws_message(%{"event" => "trade"} = msg, state) do
    trade = message_to_trade(msg) |> IO.inspect(label: "trade")

    {:noreply, state}
  end

  def handle_ws_message(msg, state) do
    IO.inspect(msg, label: "unhandled message")
    {:noreply, state}
  end

  @impl true
  def subscription_frames(currency_pairs) do
    currency_pairs
    |> Enum.map(&currency_encoder/1)
    |> Enum.map(&subscription_frame/1)
  end

  defp subscription_frame(currency_pair) do
    msg =
      %{
        "event" => "bts:subscribe",
        "data" => %{
          "channel" => "live_trades_#{currency_pair}"
        }
      }
      |> Jason.encode!()

    {:text, msg}
  end

  @spec message_to_trade(map()) :: {:ok, Trade.t()} | {:error, any()}
  def message_to_trade(%{"channel" => "live_trades_" <> currency_pair, "data" => data} = msg)
      when is_map(data) do
    with :ok <- validate_required(data, ~W(timestamp price_str amount_str)),
         {:ok, traded_at} = timestamp_to_datetime(data["timestamp"]) do

      Trade.new(
        product: Product.new(exchange_name(), currency_decoder(currency_pair)),
        price: data["price_str"],
        volume: data["amount_str"],
        traded_at: traded_at
      )
    else
      {:error, _reason} = error -> error
    end
  end
  def message_to_trade(_msg), do: {:error, :invalid_trade_message}

  @spec timestamp_to_datetime(String.t()) :: {:ok, DateTime.t()} | {:error, atom()}
  defp timestamp_to_datetime(ts) do
    case Integer.parse(ts) do
      {timestamp, _} -> 
        DateTime.from_unix(timestamp)
      :error ->
        {:error, :invalid_timestamp_string}
    end
  end

  def currency_encoder({k, v}), do: "#{k}#{v}"

  def currency_decoder(<<k::bytes-size(3)>> <> v = currency_pair) do
    {String.to_existing_atom(k), String.to_existing_atom(v)}
  end
end
