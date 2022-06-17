import Charts
import WooFoundation
import Yosemite
import SwiftUI

/// A UIKit-wrapper for the store stats chart.
///
@available(iOS 16, *)
final class StoreStatsV4ChartHostingController: UIHostingController<StoreStatsChart> {
    init(intervals: [StoreStatsChartData],
         timeRange: StatsTimeRangeV4,
         intervalSelectionHandler: @escaping (Int) -> Void) {
        super.init(rootView: StoreStatsChart(intervals: intervals,
                                             timeRange: timeRange,
                                             onIntervalSelected: intervalSelectionHandler))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// A struct for data to be displayed on a Swift chart.
///
struct StoreStatsChartData: Identifiable {
    var id: String { UUID().uuidString }

    let date: Date
    let revenue: Double
}

/// Chart for store stats build with Swift Charts.
///
@available(iOS 16, *)
struct StoreStatsChart: View {
    let intervals: [StoreStatsChartData]
    let timeRange: StatsTimeRangeV4
    let onIntervalSelected: (Int) -> Void

    @State private var selectedDate: Date?
    @State private var selectedRevenue: Double?

    private var hasRevenue: Bool {
        intervals.map { $0.revenue }.contains { $0 != 0 }
    }

    private var xAxisStride: Calendar.Component {
        switch timeRange {
        case .today:
            return .hour
        case .thisWeek, .thisMonth:
            return .day
        case .thisYear:
            return .month
        }
    }

    private var xAxisStrideCount: Int {
        switch timeRange {
        case .today:
            return 5
        case .thisWeek:
            return 1
        case .thisMonth:
            return 5
        case .thisYear:
            return 3
        }
    }

    private func xAxisLabelFormatStyle(for date: Date) -> Date.FormatStyle {
        switch timeRange {
        case .today:
            return .dateTime.hour()
        case .thisWeek, .thisMonth:
            if date == intervals.first?.date {
                return .dateTime.month(.abbreviated).day(.twoDigits)
            }
            return .dateTime.day(.twoDigits)
        case .thisYear:
            return .dateTime.month(.abbreviated)
        }
    }

    private var yAxisStride: Double {
        let minValue = intervals.map { $0.revenue }.min() ?? 0
        let maxValue = intervals.map { $0.revenue }.max() ?? 0
        return (minValue + maxValue) / 2
    }

    private func yAxisLabel(for revenue: Double) -> String {
        if revenue == 0.0 {
            // Do not show the "0" label on the Y axis
            return ""
        } else {
            let currencySymbol = ServiceLocator.currencySettings.symbol(from: ServiceLocator.currencySettings.currencyCode)
            return CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)
                .formatCurrency(using: revenue.humanReadableString(shouldHideDecimalsForIntegerAbbreviatedValue: true),
                                currencyPosition: ServiceLocator.currencySettings.currencyPosition,
                                currencySymbol: currencySymbol,
                                isNegative: revenue.sign == .minus)
        }
    }

    var body: some View {
        Chart(intervals) { item in
            LineMark(x: .value("Date", item.date),
                     y: .value("Revenue", item.revenue))
            .foregroundStyle(Color(Constants.chartLineColor))

            if !hasRevenue {
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

            if let selectedDate = selectedDate, hasRevenue {
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
            AxisMarks(values: .stride(by: xAxisStride, count: xAxisStrideCount)) { date in
                AxisValueLabel(format: xAxisLabelFormatStyle(for: date.as(Date.self) ?? Date()))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .stride(by: yAxisStride)) { value in
                AxisGridLine()
                AxisValueLabel(yAxisLabel(for: value.as(Double.self) ?? 0))
            }
        }
        .chartYAxis(hasRevenue ? .visible : .hidden)
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
        selectedDate = intervals
            .sorted(by: {
                abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
            })
            .first?.date
        selectedRevenue = intervals.first(where: { $0.date == selectedDate })?.revenue
        if let index = intervals.firstIndex(where: { $0.date == selectedDate }) {
            onIntervalSelected(index)
        }
    }
}

@available(iOS 16, *)
private extension StoreStatsChart {
    enum Constants {
        static var chartLineColor: UIColor {
            UIColor(light: .withColorStudio(.wooCommercePurple, shade: .shade50),
                    dark: .withColorStudio(.wooCommercePurple, shade: .shade30))
        }
        static let chartHighlightLineColor: UIColor = .accent
        static let chartGradientTopColor: UIColor = UIColor(light: .withColorStudio(.wooCommercePurple, shade: .shade50).withAlphaComponent(0.1),
                                                            dark: UIColor(red: 204.0/256, green: 204.0/256, blue: 204.0/256, alpha: 0.3))
        static let chartGradientBottomColor: UIColor = .clear.withAlphaComponent(0)
        static let chartPadding: CGFloat = 8
        static let annotationPadding: CGFloat = 4
    }
}

@available(iOS 16, *)
struct StoreStatsV4Chart_Previews: PreviewProvider {
    static var previews: some View {
        let data: [StoreStatsChartData] = [
            .init(date: Date(), revenue: 1299),
            .init(date: Date().addingTimeInterval(3000), revenue: 3245),
        ]
        StoreStatsChart(intervals: data, timeRange: .thisWeek) { _ in }
    }
}
