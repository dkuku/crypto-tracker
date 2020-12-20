defmodule Poeticoins do
  defdelegate subscribe_to_trades(product), to: Poeticoins.Exchanges, as: :subscribe
  defdelegate unsubscribe_from_trades(product), to: Poeticoins.Exchanges, as: :unsubscribe
  defdelegate get_last_trade(product), to: Poeticoins.Historical
  defdelegate get_last_trades(products), to: Poeticoins.Historical
  defdelegate available_products, to: Poeticoins.Exchanges
end
