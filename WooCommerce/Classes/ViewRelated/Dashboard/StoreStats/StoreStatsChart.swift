import Charts
import SwiftUI

/// Chart for store performance built with Swift Charts.
/// Technical notes: paNNhX-tA-p2
///
struct StoreStatsChart: View {
    @ObservedObject private var viewModel: StoreStatsChartViewModel
    let onIntervalSelected: (Int?) -> Void

    @State private var selectedDate: Date?
    @State private var selectedRevenue: Double?
    @State private var selectedIndex: Int?

    init(viewModel: StoreStatsChartViewModel,
         onIntervalSelected: @escaping (Int?) -> Void) {
        self.viewModel = viewModel
        self.onIntervalSelected = onIntervalSelected
    }

    var body: some View {
        Chart(viewModel.intervals) { item in
            // Line for the chart
            LineMark(x: .value(Localization.xValue, item.date),
                     y: .value(Localization.yValue, item.revenue))
            .foregroundStyle(Constants.chartLineColor)

            // No revenue text and horizontal line
            if !viewModel.hasRevenue {
                RuleMark(y: .value(Localization.zeroRevenue, 0))
                    .foregroundStyle(Constants.noRevenueLineColor)
            }

            // Gradient area
            AreaMark(x: .value(Localization.xValue, item.date),
                     y: .value(Localization.yValue, item.revenue))
            .foregroundStyle(.linearGradient(colors: [Constants.chartGradientTopColor,
                                                      Constants.chartGradientBottomColor],
                                             startPoint: .top,
                                             endPoint: .bottom))

            // Vertical line for a selected point
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
            AxisMarks(preset: .aligned, values: .stride(by: viewModel.xAxisStride,
                                                        count: viewModel.xAxisStrideCount,
                                                        roundLowerBound: true,
                                                        roundUpperBound: true)) { date in
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
            // Overlay to handle tap and drag gestures
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .gesture(DragGesture()
                        .onChanged { value in
                            // Only show selection and don't trigger updating selected index.
                            updateSelectedDate(at: value.location,
                                               proxy: proxy,
                                               geometry: geometry)
                        }
                        .onEnded { value in
                            updateSelectedDate(at: value.location,
                                               proxy: proxy,
                                               geometry: geometry)
                            updateSelectedIndex()
                        }
                    )
                    .onTapGesture { location in
                        updateSelectedDate(at: location,
                                           proxy: proxy,
                                           geometry: geometry)
                        updateSelectedIndex()
                    }
            }
        }
        .padding(Constants.chartPadding)
        .if(!viewModel.hasRevenue) { $0.overlay { emptyChartOverlay } }
    }

    private func updateSelectedDate(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        guard viewModel.hasRevenue else {
            return
        }

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
    }

    private func updateSelectedIndex() {
        if let index = viewModel.intervals.firstIndex(where: { $0.date == selectedDate }) {
            if index == selectedIndex {
                onIntervalSelected(nil)
                selectedIndex = nil
                selectedDate = nil
                selectedRevenue = nil
            } else {
                selectedIndex = index
                onIntervalSelected(index)
            }
        }
    }
}

private extension StoreStatsChart {
    var emptyChartOverlay: some View {
        // Simulate an empty chart
        VStack {
            Divider()
            Spacer()
            Divider()
            Spacer()
            Divider()
            Spacer()
        }
        .overlay {
            Image(.magnifyingGlassNotFound)
                .opacity(Constants.EmptyChartOverlay.opacity)
                .padding(.bottom, Constants.EmptyChartOverlay.bottomPadding)
        }
        .renderedIf(!viewModel.hasRevenue)
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
        static var noRevenueLineColor = Color(.listForeground(modal: false))
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

        enum EmptyChartOverlay {
            static let opacity: CGFloat = 0.5
            static let bottomPadding: CGFloat = 32
        }
    }
}

#if DEBUG

private extension StoreStatsChartViewModel {
    static let sampleDataForThisWeek: [StoreStatsChartData] = {
        let startOfWeek = Date().startOfWeek(timezone: .current)!
        var data = [StoreStatsChartData]()
        var day = 0
        while day < 7 {
            data.append(StoreStatsChartData(date: startOfWeek.adding(days: day)!, revenue: Double.random(in: 0...1000)))
            day += 1
        }
        return data
    }()
}

#Preview {
    StoreStatsChart(viewModel: .init(intervals: StoreStatsChartViewModel.sampleDataForThisWeek,
                                     timeRange: .thisWeek)) { _ in }
}

#endif
