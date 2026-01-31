// Chart.js Hook for Phoenix LiveView

let ChartJS;

// Import Chart.js
if (typeof window !== 'undefined' && window.Chart) {
  ChartJS = window.Chart;
}

const Chart = {
  mounted() {
    console.log("Chart hook mounted");

    // Load Chart.js if not available
    if (!ChartJS) {
      this.loadChartJS();
    } else {
      this.initChart();
    }
  },

  loadChartJS() {
    const script = document.createElement('script');
    script.src = 'https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.js';
    script.onload = () => {
      ChartJS = window.Chart;
      this.initChart();
    };
    document.head.appendChild(script);
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
    this.chartInstance = new ChartJS(canvas, {
      type: chartType,
      data: data,
      options: chartOptions
    });

    console.log('Chart initialized:', chartType);
  },

  getDefaultColors(count) {
    const colors = [
      '#6366F1', '#10B981', '#F59E0B', '#EF4444',
      '#8B5CF6', '#EC4899', '#14B8A6', '#F97316'
    ];
    return Array.from({length: count}, (_, i) => colors[i % colors.length]);
  },

  updated() {
    console.log("Chart hook updated");
    // Re-initialize chart with new data
    this.initChart();
  },

  destroyed() {
    console.log("Chart hook destroyed");
    // Destroy chart instance
    if (this.chartInstance) {
      this.chartInstance.destroy();
      this.chartInstance = null;
    }
  }
};

export default Chart;
