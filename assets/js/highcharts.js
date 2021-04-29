import Highcharts from 'highcharts/highstock';
import darkTheme from 'highcharts/themes/high-contrast-dark'
darkTheme(Highcharts)
Highcharts.theme = {
    colors: ['#58afff', '#58afff', '#ED561B', '#DDDF00', '#24CBE5', '#64E572',
        '#FF9655', '#FFF263', '#6AF9C4'],
    chart: {
        backgroundColor: 'transparent'
    },
};
Highcharts.setOptions(Highcharts.theme);
let config = {
    title: {
        text: "Product name"
    },

    series: [
        {
            name: "Price",
            data: [],
            tooltip: {
                valueDecimals: 2
            }
        },
        {
            type: 'column',
            name: 'Volume',
            data: [],
            yAxis: 1
        }
    ],

    yAxis: [
        {
            labels: {
                align: 'right',
                x: -3
            },
            title: {
                text: 'Price'
            },
            height: '60%',
            lineWidth: 2,
            resize: {
                enabled: true
            }
        }, {
            labels: {
                align: 'right',
                x: -3
            },
            title: {
                text: 'Volume'
            },
            top: '65%',
            height: '35%',
            offset: 0,
            lineWidth: 2
        }],
};

let HighchartsHook = {
    mounted() {
        let productId = this.el.dataset.productId,
            event = `new-trade:${productId}`,
            self = this;
        config.title.text = productId

        this.trades = [];
        this.plot = new Highcharts.stockChart('stockchart-container', config)

        this.handleEvent(event, (payload) => self.handleNewTrade(payload));
    },
    handleNewTrade(trade) {
        let price = parseFloat(trade.price),
            timestamp = trade.traded_at,
            volume = parseFloat(trade.volume);

        this.plot.series[0].addPoint([timestamp, price])
        this.plot.series[1].addPoint([timestamp, volume])
    }
}

export { HighchartsHook }
