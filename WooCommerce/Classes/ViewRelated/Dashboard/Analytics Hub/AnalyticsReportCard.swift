import SwiftUI

/// Reusable report card made for the Analytics Hub.
///
struct AnalyticsReportCard: View {

    let title: String
    let leadingTitle: String
    let leadingValue: String
    let leadingDelta: String?
    let leadingDeltaColor: UIColor?
    let leadingDeltaTextColor: UIColor?
    let leadingChartData: [Double]
    let leadingChartColor: UIColor?
    let trailingTitle: String
    let trailingValue: String
    let trailingDelta: String?
    let trailingDeltaColor: UIColor?
    let trailingDeltaTextColor: UIColor?
    let trailingChartData: [Double]
    let trailingChartColor: UIColor?

    let isRedacted: Bool

    let showSyncError: Bool
    let syncErrorMessage: String

    // Layout metrics that scale based on accessibility changes
    @ScaledMetric private var scaledChartWidth: CGFloat = Layout.chartWidth

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.titleSpacing) {

            Text(title)
                .foregroundColor(Color(.text))
                .footnoteStyle()

            HStack(alignment: .top, spacing: Layout.columnOutterSpacing) {

                /// Leading Column
                ///
                VStack(alignment: .leading, spacing: Layout.columnInnerSpacing) {

                    Text(leadingTitle)
                        .calloutStyle()

                    Text(leadingValue)
                        .titleStyle()
                        .redacted(reason: isRedacted ? .placeholder : [])
                        .shimmering(active: isRedacted)

                    AdaptiveStack(horizontalAlignment: .leading) {
                        if let leadingDelta, let leadingDeltaColor, let leadingDeltaTextColor {
                            DeltaTag(value: leadingDelta, backgroundColor: leadingDeltaColor, textColor: leadingDeltaTextColor)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .redacted(reason: isRedacted ? .placeholder : [])
                                .shimmering(active: isRedacted)
                        }

                        if leadingChartData.isNotEmpty, let leadingChartColor {
                            AnalyticsLineChart(dataPoints: leadingChartData, lineChartColor: leadingChartColor)
                                .aspectRatio(Layout.chartAspectRatio, contentMode: .fit)
                                .frame(maxWidth: scaledChartWidth)
                        }
                    }

                }
                .frame(maxWidth: .infinity, alignment: .leading)

                /// Trailing Column
                ///
                VStack(alignment: .leading, spacing: Layout.columnInnerSpacing) {
                    Text(trailingTitle)
                        .calloutStyle()

                    Text(trailingValue)
                        .titleStyle()
                        .redacted(reason: isRedacted ? .placeholder : [])
                        .shimmering(active: isRedacted)

                    AdaptiveStack(horizontalAlignment: .leading) {
                        if let trailingDelta, let trailingDeltaColor, let trailingDeltaTextColor {
                            DeltaTag(value: trailingDelta, backgroundColor: trailingDeltaColor, textColor: trailingDeltaTextColor)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .redacted(reason: isRedacted ? .placeholder : [])
                                .shimmering(active: isRedacted)
                        }

                        if trailingChartData.isNotEmpty, let trailingChartColor {
                            AnalyticsLineChart(dataPoints: trailingChartData, lineChartColor: trailingChartColor)
                                .aspectRatio(Layout.chartAspectRatio, contentMode: .fit)
                                .frame(maxWidth: scaledChartWidth)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if showSyncError {
               Text(syncErrorMessage)
                   .foregroundColor(Color(.text))
                   .subheadlineStyle()
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
        static let columnOutterSpacing: CGFloat = 28
        static let columnInnerSpacing: CGFloat = 10
        static let chartHeight: CGFloat = 32
        static let chartWidth: CGFloat = 72
        static let chartAspectRatio: CGFloat = 2.25
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
                            leadingDeltaTextColor: .textInverted,
                            leadingChartData: [0.0, 10.0, 2.0, 20.0, 15.0, 40.0, 0.0, 10.0, 2.0, 20.0, 15.0, 50.0],
                            leadingChartColor: .withColorStudio(.green, shade: .shade40),
                            trailingTitle: "Net Sales",
                            trailingValue: "$3.232",
                            trailingDelta: "-3%",
                            trailingDeltaColor: .withColorStudio(.red, shade: .shade40),
                            trailingDeltaTextColor: .textInverted,
                            trailingChartData: [50.0, 15.0, 20.0, 2.0, 10.0, 0.0, 40.0, 15.0, 20.0, 2.0, 10.0, 0.0],
                            trailingChartColor: .withColorStudio(.red, shade: .shade40),
                            isRedacted: false,
                            showSyncError: false,
                            syncErrorMessage: "")
            .previewLayout(.sizeThatFits)

        AnalyticsReportCard(title: "REVENUE",
                            leadingTitle: "Total Sales",
                            leadingValue: "-",
                            leadingDelta: "0%",
                            leadingDeltaColor: .withColorStudio(.gray, shade: .shade0),
                            leadingDeltaTextColor: .text,
                            leadingChartData: [],
                            leadingChartColor: .withColorStudio(.gray, shade: .shade30),
                            trailingTitle: "Net Sales",
                            trailingValue: "-",
                            trailingDelta: "0%",
                            trailingDeltaColor: .withColorStudio(.gray, shade: .shade0),
                            trailingDeltaTextColor: .text,
                            trailingChartData: [],
                            trailingChartColor: .withColorStudio(.gray, shade: .shade30),
                            isRedacted: false,
                            showSyncError: true,
                            syncErrorMessage: "Error loading revenue analytics")
            .previewLayout(.sizeThatFits)
            .previewDisplayName("No data")

        AnalyticsReportCard(title: "SESSIONS",
                            leadingTitle: "Views",
                            leadingValue: "1,458",
                            leadingDelta: nil,
                            leadingDeltaColor: nil,
                            leadingDeltaTextColor: nil,
                            leadingChartData: [],
                            leadingChartColor: nil,
                            trailingTitle: "Conversion Rate",
                            trailingValue: "4.5%",
                            trailingDelta: nil,
                            trailingDeltaColor: nil,
                            trailingDeltaTextColor: nil,
                            trailingChartData: [],
                            trailingChartColor: nil,
                            isRedacted: false,
                            showSyncError: true,
                            syncErrorMessage: "")
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Current period only")
    }
}
