defmodule PoeticoinsWeb.CryptoDashboardLive do
  use PoeticoinsWeb, :live_view
  alias Poeticoins.Product
  import PoeticoinsWeb.ProductHelpers

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(
        products: [],
        timezone: get_timezone_from_connection(socket)
      )

    {:ok, socket}
  end

  def handle_params(%{"products" => product_ids} = params, _url, socket) do
    new_products = Enum.map(product_ids, &product_from_string/1)
    diff = List.myers_difference(socket.assigns.products, new_products)

    socket =
      diff
      |> Keyword.get_values(:del)
      |> List.flatten()
      |> Enum.reduce(socket, &remove_product(&2, &1))

    socket =
      diff
      |> Keyword.get_values(:ins)
      |> List.flatten()
      |> Enum.reduce(socket, &add_product(&2, &1))

    {:noreply, socket}
  end

  def handle_params(_params, _url, socket), do: {:noreply, socket}

  def handle_info({:new_trade, trade}, socket) do
    send_update(PoeticoinsWeb.ProductComponent, id: trade.product, trade: trade)
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
    product_ids =
      socket.assigns.products
      |> Enum.map(&to_string/1)
      |> Kernel.++([product_id])
      |> Enum.uniq()

    socket = push_patch(socket, to: Routes.live_path(socket, __MODULE__, products: product_ids))
    {:noreply, socket}
  end

  def handle_event("add-product", %{} = event, socket) do
    {:noreply, socket}
  end

  def handle_event("remove-product", %{"product-id" => product_id} = _params, socket) do
    product_ids =
      socket.assigns.products
      |> Enum.map(&to_string/1)
      |> Kernel.--([product_id])
      |> Enum.uniq()

    socket = push_patch(socket, to: Routes.live_path(socket, __MODULE__, products: product_ids))
    {:noreply, socket}
  end

  defp product_from_string(product_id) do
    [exchange, pair] = String.split(product_id, ":")
    Product.new(exchange, pair)
  end

  defp add_product(socket, product) do
    Poeticoins.subscribe_to_trades(product)

    socket
    |> update(:products, &(&1 ++ [product]))
  end

  defp remove_product(socket, product) do
    Poeticoins.unsubscribe_from_trades(product)

    socket
    |> update(:products, &(&1 -- [product]))
  end

  defp group_products_by_exchange_name do
    Poeticoins.available_products()
    |> Enum.group_by(& &1.exchange_name)
  end

  defp get_timezone_from_connection(socket) do
    case get_connect_params(socket) do
      %{"timezone" => tz} when not is_nil(tz) -> tz
      _ -> "UTC"
    end
  end
end
