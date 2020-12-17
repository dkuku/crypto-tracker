defmodule Poeticoins.Exchanges.BitstampClient do
  alias Poeticoins.{Trade, Product}
  alias Poeticoins.Exchanges.Client
  import Client, only: [validate_required: 2]

  @behaviour Client

  @impl true
  def exchange_name(), do: "bitstamp"

  @impl true
  def server_host(), do: 'ws.bitstamp.net'
  @impl true
  def server_port(), do: 443

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
    Enum.map(currency_pairs, &subscription_frame/1)
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
        product: Product.new(exchange_name(), currency_pair),
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
end
