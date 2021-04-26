defmodule PoeticoinsWeb.CryptoDashboardLive do
  use PoeticoinsWeb, :live_view
  alias Poeticoins.Product

  def mount(_params, _session, socket) do
    products = []
    trades = %{}

    if socket.connected? do
      Enum.each(products, &Poeticoins.subscribe_to_trades(&1))
    end

    socket = assign(socket, trades: trades, products: products)

    {:ok, socket}
  end

  def handle_info({:new_trade, trade}, socket) do
    socket = update(socket, :trades, &Map.put(&1, trade.product, trade))
    {:noreply, socket}
  end

  def handle_event("filter-products", %{"search" => search} = event, socket) do
    products =
      Poeticoins.available_products()
      |> Enum.filter(fn product ->
        String.downcase(product.exchange_name) =~ String.downcase(search) or
        String.downcase(product.currency_pair) =~ String.downcase(search)
      end)
    {:noreply, assign(socket, :products, products)}
  end
  def handle_event("add-product", %{"product_id" => product_id} = event, socket) do
    [exchange, pair] = String.split(product_id, ":")
    product = Product.new(exchange, pair)
    socket = maybe_add_product(socket, product)
    {:noreply, socket}
  end
  def handle_event("add-product", %{} = event, socket) do
    {:noreply, socket}
  end

  defp add_product(socket, product) do
    Poeticoins.subscribe_to_trades(product)

    socket =
      socket
      |> update(:products, &(&1 ++ [product]))
      |> update(:trades, fn trades ->
        trade = Poeticoins.get_last_trade(product)
        Map.put(trades, product, trade)
      end)
  end

  defp maybe_add_product(socket, product) do
    if product not in socket.assigns.products do
      socket
      |> add_product(product)
      |> put_flash(:info, "#{product.exchange_name} - #{product.currency_pair} added successfully" )
    else
      socket
      |> put_flash(:error, "#{product.exchange_name} - #{product.currency_pair} was already added" )
    end
  end
end
