import Charts
import SwiftUI

/// A UIKit-wrapper for the store stats chart.
///
@available(iOS 16, *)
final class StoreStatsV4ChartHostingController: UIHostingController<StoreStatsV4Chart> {
    init(intervals: [ChartData]) {
        super.init(rootView: StoreStatsV4Chart(intervals: intervals))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// A struct for data to be displayed on a Swift chart.
/// In need of a better name.
///
struct ChartData: Identifiable {
    var id: String { UUID().uuidString }

    let xValue: String
    let yValue: Double
}

/// Chart for store stats build with Swift Charts.
///
@available(iOS 16, *)
struct StoreStatsV4Chart: View {
    let intervals: [ChartData]

    var hasRevenue: Bool {
        intervals.map { $0.yValue }.contains { $0 != 0 }
    }

    var body: some View {
        Chart(intervals) { item in
            LineMark(x: .value("Time", item.xValue),
                     y: .value("Revenue", item.yValue))
            .foregroundStyle(Color(Constants.chartLineColor))

            if !hasRevenue {
                RuleMark(y: .value("Average value", 0))
                    .annotation(position: .overlay, alignment: .center) {
                        Text("No revenue this period")
                            .padding(4)
                            .background(Color(UIColor.systemBackground))
                    }
            }

            AreaMark(x: .value("Time", item.xValue),
                     y: .value("Revenue", item.yValue))
            .foregroundStyle(.linearGradient(colors: [Color(Constants.chartGradientTopColor), Color(Constants.chartGradientBottomColor)], startPoint: .top, endPoint: .bottom))
        }
        .chartYAxis(hasRevenue ? .visible : .hidden)
    }
}

@available(iOS 16, *)
private extension StoreStatsV4Chart {
    enum Constants {
        static var chartLineColor: UIColor {
            UIColor(light: .withColorStudio(.wooCommercePurple, shade: .shade50),
                    dark: .withColorStudio(.wooCommercePurple, shade: .shade30))
        }
        static let chartHighlightLineColor: UIColor = .accent
        static let chartGradientTopColor: UIColor = UIColor(light: .withColorStudio(.wooCommercePurple, shade: .shade50).withAlphaComponent(0.1),
                                                            dark: UIColor(red: 204.0/256, green: 204.0/256, blue: 204.0/256, alpha: 0.3))
        static let chartGradientBottomColor: UIColor = .clear.withAlphaComponent(0)
    }
}

@available(iOS 16, *)
struct StoreStatsV4Chart_Previews: PreviewProvider {
    static var previews: some View {
        let data: [ChartData] = [
            .init(xValue: "Jan", yValue: 1299),
            .init(xValue: "Feb", yValue: 1000),
            .init(xValue: "Mar", yValue: 3084)
        ]
        StoreStatsV4Chart(intervals: data)
    }
}
