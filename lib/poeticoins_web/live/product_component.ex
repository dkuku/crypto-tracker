defmodule PoeticoinsWeb.ProductComponent do
  use PoeticoinsWeb, :live_component
  import PoeticoinsWeb.ProductHelpers

  def update(%{trade: trade}, socket) when not is_nil(trade) do
      socket = assign(socket, :trade, trade)
    {:ok, socket}
  end
    
  def update(assigns, socket) do
    product = assigns.id
    socket =
      socket
      |> assign(:product, product)
      |> assign(:trade, Poeticoins.get_last_trade(product))
    {:ok, socket}
  end

  def render(%{trade: trade} = assigns) when not is_nil(trade) do
    ~L"""
    <div class="product-component">
      <button class="remove" phx-click="remove-product" phx-value-product-id="<%= to_string(@product) %>">X</button>
      <div class="currency-container">
        <img src="<%= crypto_icon(@socket, @product) %>" class="icon" />
        <div class="crypto-name">
          <%= crypto_name(@product) %>
        </div>
      </div>
      <div class="price-container">
        <ul class="fiat-symbols">
          <%= for fiat <- fiat_symbols() do %>
            <li class="<%= if fiat_symbol(@product) == fiat, do: "active" %>">
              <%= fiat %>
            </li>
          <% end %>
        </ul>
        <div class="price">
          <%= @trade.price %>
          <%= fiat_character(@product) %>
        </div>
      </div>
      <div class="exchange-name">
        <%= @trade.product.exchange_name %>
      </div>
      <div class="trade-time">
        <%= human_datetime(@trade.traded_at) %>
      </div>
    </div>
    """
  end
  def render(assigns) do
    ~L"""
    <div class="product-component">
      <div class="currency-container">
        <img src="<%= crypto_icon(@socket, @product) %>" class="icon" />
        <div class="crypto-name">
          <%= crypto_name(@product) %>
        </div>
      </div>
      <div class="price-container">
        <ul class="fiat-symbols">
          <%= for fiat <- fiat_symbols() do %>
            <li class="<%= if fiat_symbol(@product) == fiat, do: "active" %>">
              <%= fiat %>
            </li>
          <% end %>
        </ul>
        <div class="price">
          ...
          <%= fiat_character(@product) %>
        </div>
      </div>
      <div class="exchange-name">
        <%= @product.exchange_name %>
      </div>
    </div>
    """
  end
end
