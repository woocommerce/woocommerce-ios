import Charts
import SwiftUI

/// Chart for store performance built with Swift Charts.
/// Technical notes: paNNhX-tA-p2
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
            LineMark(x: .value(Localization.xValue, item.date),
                     y: .value(Localization.yValue, item.revenue))
            .foregroundStyle(Constants.chartLineColor)

            if !viewModel.hasRevenue {
                RuleMark(y: .value(Localization.zeroRevenue, 0))
                    .annotation(position: .overlay, alignment: .center) {
                        Text("No revenue this period")
                            .font(.footnote)
                            .padding(Constants.annotationPadding)
                            .background(Color(UIColor.systemBackground))
                    }
            }

            AreaMark(x: .value(Localization.xValue, item.date),
                     y: .value(Localization.yValue, item.revenue))
            .foregroundStyle(.linearGradient(colors: [Constants.chartGradientTopColor,
                                                      Constants.chartGradientBottomColor],
                                             startPoint: .top,
                                             endPoint: .bottom))

            if let selectedDate = selectedDate, viewModel.hasRevenue {
                RuleMark(x: .value(Localization.xSelectedValue, selectedDate))
                    .foregroundStyle(Constants.chartHighlightLineColor)

                if let selectedRevenue = selectedRevenue {
                    PointMark(x: .value(Localization.xSelectedValue, selectedDate),
                              y: .value(Localization.ySelectedValue, selectedRevenue))
                    .foregroundStyle(Constants.chartHighlightLineColor)
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
    enum Localization {
        static let xValue = NSLocalizedString(
            "storeStatsChart.xValue",
            value: "Date",
            comment: "Value for the x-Axis of the store stats chart on the Dashboard screen"
        )
        static let yValue = NSLocalizedString(
            "storeStatsChart.yValue",
            value: "Revenue",
            comment: "Value for the y-Axis of the store stats chart on the Dashboard screen"
        )
        static let zeroRevenue = NSLocalizedString(
            "storeStatsChart.zeroRevenue",
            value: "Zero revenue",
            comment: "Value for the y-Axis of the store stats chart on the Dashboard screen when there is no revenue"
        )
        static let noRevenueText = NSLocalizedString(
            "storeStatsChart.noRevenueText",
            value: "No revenue this period",
            comment: "Text on the store stats chart on the Dashboard screen when there is no revenue"
        )
        static let xSelectedValue = NSLocalizedString(
            "storeStatsChart.xSelectedValue",
            value: "Selected date",
            comment: "Value for the x-Axis of any selected point on the store stats chart on the Dashboard screen"
        )
        static let ySelectedValue = NSLocalizedString(
            "storeStatsChart.ySelectedValue",
            value: "Selected revenue",
            comment: "Value for the y-Axis of any selected point on the store stats chart on the Dashboard screen"
        )
    }

    enum Constants {
        static var chartLineColor = Color(
            light: .withColorStudio(name: .wooCommercePurple, shade: .shade50),
            dark: .withColorStudio(name: .wooCommercePurple, shade: .shade30)
        )
        static let chartHighlightLineColor = Color.withColorStudio(name: .pink, shade: .shade50)
        static let chartGradientTopColor = Color(
            light: .withColorStudio(name: .wooCommercePurple, shade: .shade50).opacity(0.1),
            dark: Color(UIColor(red: 204.0/256, green: 204.0/256, blue: 204.0/256, alpha: 0.3))
        )
        static let chartGradientBottomColor = Color.clear
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
