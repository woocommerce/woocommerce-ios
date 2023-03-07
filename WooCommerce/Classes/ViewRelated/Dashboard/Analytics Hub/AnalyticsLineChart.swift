import SwiftUI
import Charts

/// `SwiftUI` representable type for `LineChartView` to use in the Analytics Hub
struct AnalyticsLineChart: UIViewRepresentable {

    /// Data points (values) to display in the line chart
    ///
    let dataPoints: [Double]

    /// Color for the line and gradient
    ///
    let lineChartColor: UIColor

    func makeUIView(context: Context) -> LineChartView {
        let lineChartView = LineChartView()
        configureChart(lineChartView)
        return lineChartView
    }

    func updateUIView(_ uiView: LineChartView, context: Context) {
        configureChartData(for: uiView, data: dataPoints, lineColor: lineChartColor)
    }

    func configureChart(_ lineChartView: LineChartView) {
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

    func configureChartData(for lineChartView: LineChartView, data dataPoints: [Double], lineColor: UIColor) {
        // Adds provided `dataPoints` to data set
        var dataEntries: [ChartDataEntry] = []
        for count in (0..<dataPoints.count) {
            dataEntries.append(ChartDataEntry.init(x: Double(count), y: dataPoints[count]))
        }
        let dataSet = LineChartDataSet(entries: dataEntries, label: "Data")

        // Configures data set
        dataSet.lineWidth = Constants.lineWidth
        dataSet.setColor(lineChartColor)
        dataSet.drawCirclesEnabled = false // Do not draw circles on the data points
        dataSet.drawValuesEnabled = false // Do not draw value labels on the data points
        dataSet.highlightEnabled = false // Do not allow highlighting a data point when tapped

        // Configures gradient to fill the area from top to bottom.
        let gradientColorSpace = CGColorSpaceCreateDeviceRGB()
        let gradientColors = [lineChartColor.withAlphaComponent(0.0).cgColor, lineChartColor.withAlphaComponent(0.8).cgColor] as CFArray
        let locations: [CGFloat] = [0.0, 1.0]
        if let gradient = CGGradient(colorsSpace: gradientColorSpace, colors: gradientColors, locations: locations) {
            dataSet.fill = LinearGradientFill(gradient: gradient, angle: Constants.gradientFillAngle)
            dataSet.fillAlpha = Constants.gradientFillAlpha
            dataSet.drawFilledEnabled = true
        }

        lineChartView.data = LineChartData(dataSet: dataSet)
    }
}

private extension AnalyticsLineChart {
    enum Constants {
        static let lineWidth: CGFloat = 2.0
        static let gradientFillAngle: CGFloat = 90
        static let gradientFillAlpha: CGFloat = 1
    }
}

struct AnalyticsLineChart_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsLineChart(dataPoints: [0.0, 10.0, 2.0, 20.0, 15.0, 50.0], lineChartColor: .systemGreen)
            .aspectRatio(2.2, contentMode: .fit)
            .previewDisplayName("Positive Chart")

        AnalyticsLineChart(dataPoints: [50.0, 15.0, 20.0, 2.0, 10.0, 0.0], lineChartColor: .systemRed)
            .aspectRatio(2.2, contentMode: .fit)
            .previewDisplayName("Negative Chart")
    }
}
