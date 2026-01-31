// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

// Load Chart.js from CDN
const loadChartJS = () => {
  return new Promise((resolve) => {
    if (window.Chart) {
      resolve();
      return;
    }

    const script = document.createElement('script');
    script.src = 'https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js';
    script.onload = () => {
      console.log('Chart.js loaded');
      resolve();
    };
    document.head.appendChild(script);
  });
};

// Chart.js Hook
const ChartHook = {
  mounted() {
    console.log("Chart hook mounted");
    loadChartJS().then(() => {
      this.initChart();
    });
  },

  updated() {
    console.log("Chart hook updated");
    if (this.chartInstance) {
      this.updateChart();
    } else {
      this.initChart();
    }
  },

  initChart() {
    const canvas = this.el;
    const chartType = this.el.dataset.chartType;
    const chartData = JSON.parse(this.el.dataset.chartData);
    const chartOptions = JSON.parse(this.el.dataset.chartOptions);

    // Destroy existing chart if any
    if (this.chartInstance) {
      this.chartInstance.destroy();
    }

    // Prepare data based on chart type
    let data;
    switch (chartType) {
      case 'line':
        data = {
          labels: chartData.map(d => d.date),
          datasets: [{
            label: '用户数',
            data: chartData.map(d => d.count),
            borderColor: '#6366F1',
            backgroundColor: 'rgba(99, 102, 241, 0.1)',
            borderWidth: 3,
            fill: true,
            tension: 0.4,
            pointRadius: 4,
            pointHoverRadius: 8
          }]
        };
        break;

      case 'pie':
        data = {
          labels: chartData.map(d => d.label),
          datasets: [{
            data: chartData.map(d => d.value),
            backgroundColor: chartData.map(d => d.color || this.getDefaultColors(chartData.length)),
            borderWidth: 2,
            borderColor: '#ffffff'
          }]
        };
        break;

      case 'bar':
        data = {
          labels: chartData.labels,
          datasets: [{
            label: '操作次数',
            data: chartData.data,
            backgroundColor: chartData.colors || this.getDefaultColors(chartData.data.length),
            borderRadius: 6,
            borderWidth: 0
          }]
        };
        break;

      default:
        console.error('Unknown chart type:', chartType);
        return;
    }

    // Create chart
    this.chartInstance = new Chart(canvas, {
      type: chartType,
      data: data,
      options: chartOptions
    });

    console.log('Chart initialized:', chartType);
  },

  updateChart() {
    if (!this.chartInstance) return;

    const chartType = this.el.dataset.chartType;
    const chartData = JSON.parse(this.el.dataset.chartData);
    const chartOptions = JSON.parse(this.el.dataset.chartOptions);

    switch (chartType) {
      case 'line':
        this.chartInstance.data.labels = chartData.map(d => d.date);
        this.chartInstance.data.datasets[0].data = chartData.map(d => d.count);
        break;

      case 'pie':
        this.chartInstance.data.labels = chartData.map(d => d.label);
        this.chartInstance.data.datasets[0].data = chartData.map(d => d.value);
        break;

      case 'bar':
        this.chartInstance.data.labels = chartData.labels;
        this.chartInstance.data.datasets[0].data = chartData.data;
        break;
    }

    this.chartInstance.update();
  },

  destroyed() {
    console.log("Chart hook destroyed");
    if (this.chartInstance) {
      this.chartInstance.destroy();
      this.chartInstance = null;
    }
  },

  getDefaultColors(count) {
    const colors = [
      '#6366F1', '#10B981', '#F59E0B', '#EF4444',
      '#8B5CF6', '#EC4899', '#14B8A6', '#F97316'
    ];
    return Array.from({length: count}, (_, i) => colors[i % colors.length]);
  }
};

// Legacy ActivityChart hook (keep for backwards compatibility)
const ActivityChart = {
  mounted() {
    loadChartJS().then(() => {
      this.initChart();
    });
  },

  updated() {
    if (this.chart) {
      this.updateChart();
    }
  },

  initChart() {
    const data = JSON.parse(this.el.dataset.chart);
    const ctx = this.el.getContext('2d');

    this.chart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: data.map(d => d.date),
        datasets: [{
          label: '操作次数',
          data: data.map(d => d.count),
          borderColor: 'rgb(59, 130, 246)',
          backgroundColor: 'rgba(59, 130, 246, 0.1)',
          tension: 0.4,
          fill: true
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: true,
        plugins: {
          legend: {
            display: false
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            ticks: {
              precision: 0
            }
          }
        }
      }
    });
  },

  updateChart() {
    if (this.chart) {
      const data = JSON.parse(this.el.dataset.chart);
      this.chart.data.labels = data.map(d => d.date);
      this.chart.data.datasets[0].data = data.map(d => d.count);
      this.chart.update();
    }
  }
};

// Hooks object
let Hooks = {
  Chart: ChartHook,
  ActivityChart: ActivityChart
};

// CSRF token
let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

// Live socket
let liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
window.liveSocket = liveSocket
