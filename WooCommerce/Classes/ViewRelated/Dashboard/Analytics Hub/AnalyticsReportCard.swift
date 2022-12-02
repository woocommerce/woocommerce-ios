import SwiftUI

/// Resuable report card made for the Analytics Hub.
///
struct AnalyticsReportCard: View {

    let viewModel: AnalyticsReportCardViewModel

    // Layout metrics that scale based on accessibility changes
    @ScaledMetric private var scaledChartWidth: CGFloat = Layout.chartWidth
    @ScaledMetric private var scaledChartHeight: CGFloat = Layout.chartHeight

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.titleSpacing) {

            Text(viewModel.title)
                .foregroundColor(Color(.text))
                .footnoteStyle()

            HStack(alignment: .top, spacing: Layout.columnOutterSpacing) {

                /// Leading Column
                ///
                VStack(alignment: .leading, spacing: Layout.columnInnerSpacing) {

                    Text(viewModel.leadingTitle)
                        .calloutStyle()

                    Text(viewModel.leadingValue)
                        .titleStyle()
                        .redacted(reason: viewModel.isRedacted ? .placeholder : [])
                        .shimmering(active: viewModel.isRedacted)

                    AdaptiveStack(horizontalAlignment: .leading) {
                        DeltaTag(value: viewModel.leadingDelta, backgroundColor: viewModel.leadingDeltaColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .redacted(reason: viewModel.isRedacted ? .placeholder : [])
                            .shimmering(active: viewModel.isRedacted)

                        AnalyticsLineChart(dataPoints: viewModel.leadingChartData, lineChartColor: viewModel.leadingDeltaColor)
                            .frame(width: scaledChartWidth, height: scaledChartHeight)
                    }

                }
                .frame(maxWidth: .infinity, alignment: .leading)

                /// Trailing Column
                ///
                VStack(alignment: .leading, spacing: Layout.columnInnerSpacing) {
                    Text(viewModel.trailingTitle)
                        .calloutStyle()

                    Text(viewModel.trailingValue)
                        .titleStyle()
                        .redacted(reason: viewModel.isRedacted ? .placeholder : [])
                        .shimmering(active: viewModel.isRedacted)

                    AdaptiveStack(horizontalAlignment: .leading) {
                        DeltaTag(value: viewModel.trailingDelta, backgroundColor: viewModel.trailingDeltaColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .redacted(reason: viewModel.isRedacted ? .placeholder : [])
                            .shimmering(active: viewModel.isRedacted)

                        AnalyticsLineChart(dataPoints: viewModel.trailingChartData, lineChartColor: viewModel.trailingDeltaColor)
                            .frame(width: scaledChartWidth, height: scaledChartHeight)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if viewModel.showSyncError {
                Text(viewModel.syncErrorMessage)
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
    }
}

// MARK: Previews
struct Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsReportCard(viewModel: .init(title: "REVENUE",
                                             leadingTitle: "Total Sales",
                                             leadingValue: "$3.678",
                                             leadingDelta: "+23%",
                                             leadingDeltaColor: .withColorStudio(.green, shade: .shade40),
                                             leadingChartData: [0.0, 10.0, 2.0, 20.0, 15.0, 40.0, 0.0, 10.0, 2.0, 20.0, 15.0, 50.0],
                                             trailingTitle: "Net Sales",
                                             trailingValue: "$3.232",
                                             trailingDelta: "-3%",
                                             trailingDeltaColor: .withColorStudio(.red, shade: .shade40),
                                             trailingChartData: [50.0, 15.0, 20.0, 2.0, 10.0, 0.0, 40.0, 15.0, 20.0, 2.0, 10.0, 0.0],
                                             isRedacted: false,
                                             showSyncError: false,
                                             syncErrorMessage: ""))
            .previewLayout(.sizeThatFits)

        AnalyticsReportCard(viewModel: .init(title: "REVENUE",
                                             leadingTitle: "Total Sales",
                                             leadingValue: "-",
                                             leadingDelta: "0%",
                                             leadingDeltaColor: .withColorStudio(.gray, shade: .shade0),
                                             leadingChartData: [],
                                             trailingTitle: "Net Sales",
                                             trailingValue: "-",
                                             trailingDelta: "0%",
                                             trailingDeltaColor: .withColorStudio(.gray, shade: .shade0),
                                             trailingChartData: [],
                                             isRedacted: false,
                                             showSyncError: true,
                                             syncErrorMessage: "Error loading revenue analytics"))
            .previewLayout(.sizeThatFits)
            .previewDisplayName("No data")
    }
}
