import Charts
import SwiftUI

/// Chart for store performance built with Swift Charts.
///
struct StoreStatsChart: View {
    @ObservedObject private var viewModel: StoreStatsChartViewModel
    let onIntervalSelected: (Int) -> Void

    @State private var selectedDate: Date?
    @State private var selectedRevenue: Double?

    init(viewModel: StoreStatsChartViewModel,
         onIntervalSelected: @escaping (Int) -> Void) {
        self.viewModel = viewModel
        self.onIntervalSelected = onIntervalSelected
    }

    var body: some View {
        Chart(viewModel.intervals) { item in
            LineMark(x: .value("Date", item.date),
                     y: .value("Revenue", item.revenue))
            .foregroundStyle(Color(Constants.chartLineColor))

            if !viewModel.hasRevenue {
                RuleMark(y: .value("Zero revenue", 0))
                    .annotation(position: .overlay, alignment: .center) {
                        Text("No revenue this period")
                            .font(.footnote)
                            .padding(Constants.annotationPadding)
                            .background(Color(UIColor.systemBackground))
                    }
            }

            AreaMark(x: .value("Date", item.date),
                     y: .value("Revenue", item.revenue))
            .foregroundStyle(.linearGradient(colors: [Color(Constants.chartGradientTopColor), Color(Constants.chartGradientBottomColor)],
                                             startPoint: .top,
                                             endPoint: .bottom))

            if let selectedDate = selectedDate, viewModel.hasRevenue {
                RuleMark(x: .value("Selected date", selectedDate))
                    .foregroundStyle(Color(Constants.chartHighlightLineColor))

                if let selectedRevenue = selectedRevenue {
                    PointMark(x: .value("Selected date", selectedDate),
                              y: .value("Selected revenue", selectedRevenue))
                    .foregroundStyle(Color(Constants.chartHighlightLineColor))
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: viewModel.xAxisStride,
                                      count: viewModel.xAxisStrideCount)) { date in
                AxisValueLabel(format: viewModel.xAxisLabelFormatStyle(for: date.as(Date.self) ?? Date()))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .stride(by: viewModel.yAxisStride)) { value in
                AxisGridLine()
                AxisValueLabel(viewModel.yAxisLabel(for: value.as(Double.self) ?? 0))
            }
        }
        .chartYAxis(viewModel.hasRevenue ? .visible : .hidden)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .gesture(DragGesture()
                        .onChanged { value in
                            updateSelectedDate(at: value.location,
                                               proxy: proxy,
                                               geometry: geometry)
                        }
                    )
                    .onTapGesture { location in
                        updateSelectedDate(at: location,
                                           proxy: proxy,
                                           geometry: geometry)
                    }
            }
        }
        .padding(Constants.chartPadding)
    }

    private func updateSelectedDate(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        let xPosition = location.x - geometry[proxy.plotAreaFrame].origin.x
        guard let date: Date = proxy.value(atX: xPosition) else {
            return
        }
        selectedDate = viewModel.intervals
            .sorted(by: {
                abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
            })
            .first?.date
        selectedRevenue = viewModel.intervals.first(where: { $0.date == selectedDate })?.revenue
        if let index = viewModel.intervals.firstIndex(where: { $0.date == selectedDate }) {
            onIntervalSelected(index)
        }
    }
}

private extension StoreStatsChart {
    enum Constants {
        static var chartLineColor: UIColor {
            UIColor(light: .withColorStudio(.wooCommercePurple, shade: .shade50),
                    dark: .withColorStudio(.wooCommercePurple, shade: .shade30))
        }
        static let chartHighlightLineColor: UIColor = .withColorStudio(.pink)
        static let chartGradientTopColor: UIColor = UIColor(light: .withColorStudio(.wooCommercePurple, shade: .shade50).withAlphaComponent(0.1),
                                                            dark: UIColor(red: 204.0/256, green: 204.0/256, blue: 204.0/256, alpha: 0.3))
        static let chartGradientBottomColor: UIColor = .clear.withAlphaComponent(0)
        static let chartPadding: CGFloat = 8
        static let annotationPadding: CGFloat = 4
    }
}

#Preview {
    StoreStatsChart(viewModel: .init(intervals: [
        .init(date: Date(), revenue: 1299),
        .init(date: Date().addingTimeInterval(3000), revenue: 3245),
    ], timeRange: .thisWeek)) { _ in }
}
