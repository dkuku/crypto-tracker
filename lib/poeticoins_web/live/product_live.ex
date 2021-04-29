defmodule PoeticoinsWeb.ProductLive do
  use PoeticoinsWeb, :live_view
  import PoeticoinsWeb.ProductHelpers

  def mount(%{"id" => product_id} = _params, _session, socket) do
    product = product_from_string(product_id)
    Poeticoins.subscribe_to_trades(product)
    trade = Poeticoins.get_last_trade(product)
    socket = assign(socket,
      product: product,
      product_id: product_id,
      trade: trade,
      page_title: page_title_from_trade(trade)
    )
    if socket.connected? do
      Poeticoins.subscribe_to_trades(product)
    end
    {:ok, socket}
  end
  def handle_info({:new_trade, trade}, socket) do
    product_id = to_string(trade.product)
    event_name = "new-trade:#{product_id}"
    socket = 
      socket
      |> assign(:trade, trade)
      |> push_event(event_name, to_event(trade))
    {:noreply, socket}
  end

  def render(%{trade: trade} = assigns) when not is_nil(trade) do
    ~L"""
      <div class="highcharts-component">
        <div phx-hook="Highcharts" 
            id="product-chart-<%= to_string(@product) %>"
            data-product-id="<%= to_string(@product) %>"
            phx-update="ignore"
            >
        <div id="stockchart-container" style="height: 600px; min-width: 1000"></div>
      </div>
    </div>
    """
  end
  def render(assigns) do
    ~L"""
    <div class="">
    loading
    </div>
    """
  end

  def handle_info({:new_trade, trade}, socket) do
    socket =
      socket
      |> assign(:trade, trade)
    
    {:noreply, socket}
  end

  defp page_title_from_trade(nil), do: "..."
  defp page_title_from_trade(trade) do
    "#{fiat_character(trade.product)}#{trade.price}" <>
      " #{trade.product.currency_pair} #{trade.product.exchange_name}"
  end
end
