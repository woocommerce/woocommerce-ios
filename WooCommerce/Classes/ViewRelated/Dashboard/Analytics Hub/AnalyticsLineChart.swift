import SwiftUI
import Charts

/// `SwiftUI` representable type for `LineChartView` to use in the Analytics Hub
struct AnalyticsLineChart: UIViewRepresentable {

    /// Data to display in the line chart
    ///
    let data: LineChartData

    func makeUIView(context: Context) -> LineChartView {
        let lineChartView = LineChartView()
        configureChart(lineChartView)
        return lineChartView
    }

    func configureChart(_ lineChartView: LineChartView) {
        lineChartView.data = data

        lineChartView.chartDescription.enabled = false

        // Disables chart interactions
        lineChartView.dragXEnabled = false
        lineChartView.dragYEnabled = false
        lineChartView.setScaleEnabled(false)
        lineChartView.pinchZoomEnabled = false

        // Disables legends and axes
        lineChartView.legend.enabled = false
        lineChartView.xAxis.enabled = false
        lineChartView.leftAxis.enabled = false
        lineChartView.rightAxis.enabled = false
    }

    func updateUIView(_ uiView: LineChartView, context: Context) {
        // no-op
    }
}

struct AnalyticsLineChart_Previews: PreviewProvider {
    static var previews: some View {
        let data = LineChartData(dataSet: LineChartDataSet())
        AnalyticsLineChart(data: data)
    }
}
