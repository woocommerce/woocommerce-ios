import SwiftUI

/// Resuable report card made for the Analytics Hub.
///
struct AnalyticsReportCard: View {

    let title: String
    let leadingTitle: String
    let leadingValue: String
    let leadingDelta: String
    let leadingDeltaColor: UIColor
    let leadingChartData: [Double]
    let trailingTitle: String
    let trailingValue: String
    let trailingDelta: String
    let trailingDeltaColor: UIColor
    let trailingChartData: [Double]

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.titleSpacing) {

            Text(title)
                .foregroundColor(Color(.text))
                .footnoteStyle()

            HStack {

                /// Leading Column
                ///
                VStack(alignment: .leading, spacing: Layout.columnSpacing) {

                    Text(leadingTitle)
                        .calloutStyle()

                    Text(leadingValue)
                        .titleStyle()

                    AdaptiveStack {
                        DeltaTag(value: leadingDelta, backgroundColor: leadingDeltaColor)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        AnalyticsLineChart(dataPoints: leadingChartData, lineChartColor: leadingDeltaColor)
                            .frame(maxWidth: .infinity, maxHeight: Layout.chartMaxHeight, alignment: .trailing)
                    }

                }
                .frame(maxWidth: .infinity, alignment: .leading)

                /// Trailing Column
                ///
                VStack(alignment: .leading, spacing: Layout.columnSpacing) {
                    Text(trailingTitle)
                        .calloutStyle()

                    Text(trailingValue)
                        .titleStyle()

                    AdaptiveStack {
                        DeltaTag(value: trailingDelta, backgroundColor: trailingDeltaColor)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        AnalyticsLineChart(dataPoints: trailingChartData, lineChartColor: trailingDeltaColor)
                            .frame(maxWidth: .infinity, maxHeight: Layout.chartMaxHeight, alignment: .trailing)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(Layout.cardPadding)
    }
}

// MARK: Constants
private extension AnalyticsReportCard {
    enum Layout {
        static let titleSpacing: CGFloat = 24
        static let cardPadding: CGFloat = 16
        static let columnSpacing: CGFloat = 10
        static let chartMaxHeight: CGFloat = 48
    }
}

// MARK: Previews
struct Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsReportCard(title: "REVENUE",
                            leadingTitle: "Total Sales",
                            leadingValue: "$3.678",
                            leadingDelta: "+23%",
                            leadingDeltaColor: .withColorStudio(.green, shade: .shade40),
                            leadingChartData: [0.0, 10.0, 2.0, 20.0, 15.0, 40.0, 0.0, 10.0, 2.0, 20.0, 15.0, 50.0],
                            trailingTitle: "Net Sales",
                            trailingValue: "$3.232",
                            trailingDelta: "-3%",
                            trailingDeltaColor: .withColorStudio(.red, shade: .shade40),
                            trailingChartData: [50.0, 15.0, 20.0, 2.0, 10.0, 0.0, 40.0, 15.0, 20.0, 2.0, 10.0, 0.0])
            .previewLayout(.sizeThatFits)
    }
}
