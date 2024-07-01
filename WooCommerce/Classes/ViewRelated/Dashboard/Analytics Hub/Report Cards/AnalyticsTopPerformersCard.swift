import SwiftUI

/// Card to display a stat and a list of top performers for that stat on the Analytics Hub
///
struct AnalyticsTopPerformersCard: View {

    /// Title for the top performers card.
    ///
    let title: String

    /// Title for the top performers stat.
    ///
    let statTitle: String

    /// Value for the top performers stat. Needs to be formatted.
    ///
    let statValue: String

    /// Delta Tag Value. Needs to be formatted
    let delta: String

    /// Delta Tag background color.
    let deltaBackgroundColor: UIColor

    /// Delta Tag text color.
    let deltaTextColor: UIColor

    /// Indicates if the values should be hidden (for loading state)
    ///
    let isStatsRedacted: Bool

    /// Indicates if there was an error loading stats part of the card.
    ///
    let showStatsError: Bool

    /// Error message to display if there was an error loading stats part of the card.
    ///
    let statsErrorMessage: String

    /// Title for top performers list.
    ///
    let topPerformersTitle: String

    /// Top performers data to render.
    ///
    let topPerformersData: [TopPerformersRow.Data]

    /// Indicates if the values should be hidden (for loading state)
    ///
    let isTopPerformersRedacted: Bool

    /// Indicates if there was an error loading top performers part of the card.
    ///
    let showTopPerformersError: Bool

    /// Error message to display if there was an error loading top performers part of the card.
    ///
    let topPerformersErrorMessage: String

    /// URL for the products analytics web report
    ///
    let reportViewModel: AnalyticsReportLinkViewModel?
    @State private var showingWebReport: Bool = false

    var body: some View {
        VStack(alignment: .leading) {

            Text(title)
                .foregroundColor(Color(.text))
                .footnoteStyle()

            Text(statTitle)
                .headlineStyle()
                .padding(.top, Layout.titleSpacing)
                .padding(.bottom, Layout.columnSpacing)

            HStack {
                Text(statValue)
                    .titleStyle()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .redacted(reason: isStatsRedacted ? .placeholder : [])
                    .shimmering(active: isStatsRedacted)

                DeltaTag(value: delta, backgroundColor: deltaBackgroundColor, textColor: deltaTextColor)
                    .redacted(reason: isStatsRedacted ? .placeholder : [])
                    .shimmering(active: isStatsRedacted)
            }

            if showStatsError {
                Text(statsErrorMessage)
                    .foregroundColor(Color(.text))
                    .subheadlineStyle()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, Layout.columnSpacing)
            }

            TopPerformersView(itemTitle: topPerformersTitle.localizedCapitalized,
                              valueTitle: statTitle,
                              rows: topPerformersData,
                              isRedacted: isTopPerformersRedacted)
                .padding(.vertical, Layout.columnSpacing)

            if showTopPerformersError {
                Text(topPerformersErrorMessage)
                    .foregroundColor(Color(.text))
                    .subheadlineStyle()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, Layout.columnSpacing)
            }

            if let reportViewModel {
                AnalyticsReportLink(showingWebReport: $showingWebReport, reportViewModel: reportViewModel)
            }
        }
        .padding(Layout.cardPadding)
    }
}

// MARK: Constants
private extension AnalyticsTopPerformersCard {
    enum Layout {
        static let titleSpacing: CGFloat = 24
        static let cardPadding: CGFloat = 16
        static let columnSpacing: CGFloat = 10
    }
}


// MARK: Previews
struct AnalyticsItemsSoldCardPreviews: PreviewProvider {
    static var previews: some View {
        let imageURL = URL(string: "https://s0.wordpress.com/i/store/mobile/plans-premium.png")
        AnalyticsTopPerformersCard(title: "Products",
                               statTitle: "Items Sold",
                               statValue: "2,234",
                               delta: "+23%",
                               deltaBackgroundColor: .withColorStudio(.green, shade: .shade50),
                               deltaTextColor: .textInverted,
                               isStatsRedacted: false,
                               showStatsError: false,
                                   statsErrorMessage: "Unable to load product analytics",
                                   topPerformersTitle: "Products",
                               topPerformersData: [
                                .init(imageURL: imageURL, name: "Tabletop Photos", details: "Net Sales: $1,232", value: "32"),
                                .init(imageURL: imageURL, name: "Kentya Palm", details: "Net Sales: $800", value: "10"),
                                .init(imageURL: imageURL, name: "Love Ficus", details: "Net Sales: $599", value: "5"),
                                .init(imageURL: imageURL, name: "Bird Of Paradise", details: "Net Sales: $23.50", value: "2"),
                               ],
                               isTopPerformersRedacted: false,
                               showTopPerformersError: false,
                               topPerformersErrorMessage: "Unable to load product items sold analytics",
                               reportViewModel: .init(reportType: .products,
                                                      period: .today,
                                                      webViewTitle: "Products Report",
                                                      reportURL: URL(string: "https://woocommerce.com")!,
                                                      usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter()))
            .previewLayout(.sizeThatFits)

        AnalyticsTopPerformersCard(title: "Products",
                               statTitle: "Items Sold",
                               statValue: "-",
                               delta: "0%",
                               deltaBackgroundColor: .withColorStudio(.gray, shade: .shade0),
                               deltaTextColor: .text,
                               isStatsRedacted: false,
                               showStatsError: true,
                               statsErrorMessage: "Unable to load product analytics",
                                   topPerformersTitle: "Products",
                               topPerformersData: [],
                               isTopPerformersRedacted: false,
                               showTopPerformersError: true,
                               topPerformersErrorMessage: "Unable to load product items sold analytics",
                               reportViewModel: .init(reportType: .products,
                                                      period: .today,
                                                      webViewTitle: "Products Report",
                                                      reportURL: URL(string: "https://woocommerce.com")!,
                                                      usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter()))
            .previewLayout(.sizeThatFits)
            .previewDisplayName("No data")
    }
}
