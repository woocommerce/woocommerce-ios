import SwiftUI

/// Products Card on the Analytics Hub
///
struct AnalyticsProductCard: View {

    /// Items sold quantity. Needs to be formatted.
    ///
    let itemsSold: String

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

    /// Items Solds data to render.
    ///
    let itemsSoldData: [TopPerformersRow.Data]

    /// Indicates if the values should be hidden (for loading state)
    ///
    let isItemsSoldRedacted: Bool

    /// Indicates if there was an error loading items sold part of the card.
    ///
    let showItemsSoldError: Bool

    var body: some View {
        VStack(alignment: .leading) {

            Text(Localization.title)
                .foregroundColor(Color(.text))
                .footnoteStyle()

            Text(Localization.itemsSold)
                .headlineStyle()
                .padding(.top, Layout.titleSpacing)
                .padding(.bottom, Layout.columnSpacing)

            HStack {
                Text(itemsSold)
                    .titleStyle()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .redacted(reason: isStatsRedacted ? .placeholder : [])
                    .shimmering(active: isStatsRedacted)

                DeltaTag(value: delta, backgroundColor: deltaBackgroundColor, textColor: deltaTextColor)
                    .redacted(reason: isStatsRedacted ? .placeholder : [])
                    .shimmering(active: isStatsRedacted)
            }

            if showStatsError {
                Text(Localization.noProducts)
                    .foregroundColor(Color(.text))
                    .subheadlineStyle()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, Layout.columnSpacing)
            }

            TopPerformersView(itemTitle: Localization.title.localizedCapitalized,
                              valueTitle: Localization.itemsSold,
                              rows: itemsSoldData,
                              isRedacted: isItemsSoldRedacted)
                .padding(.top, Layout.columnSpacing)

            if showItemsSoldError {
                Text(Localization.noItemsSold)
                    .foregroundColor(Color(.text))
                    .subheadlineStyle()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, Layout.columnSpacing)
            }
        }
        .padding(Layout.cardPadding)
    }
}

// MARK: Constants
private extension AnalyticsProductCard {
    enum Localization {
        static let title = NSLocalizedString("Products", comment: "Title for the products card on the analytics hub screen.").localizedUppercase
        static let itemsSold = NSLocalizedString("Items Sold", comment: "Title for the items sold column on the products card on the analytics hub screen.")
        static let noProducts = NSLocalizedString("Unable to load product analytics",
                                                  comment: "Text displayed when there is an error loading product stats data.")
        static let noItemsSold = NSLocalizedString("Unable to load product items sold analytics",
                                                   comment: "Text displayed when there is an error loading items sold stats data.")
    }

    enum Layout {
        static let titleSpacing: CGFloat = 24
        static let cardPadding: CGFloat = 16
        static let columnSpacing: CGFloat = 10
    }
}


// MARK: Previews
struct AnalyticsProductCardPreviews: PreviewProvider {
    static var previews: some View {
        let imageURL = URL(string: "https://s0.wordpress.com/i/store/mobile/plans-premium.png")
        AnalyticsProductCard(itemsSold: "2,234",
                             delta: "+23%",
                             deltaBackgroundColor: .withColorStudio(.green, shade: .shade50),
                             deltaTextColor: .textInverted,
                             isStatsRedacted: false,
                             showStatsError: false,
                             itemsSoldData: [
                                .init(imageURL: imageURL, name: "Tabletop Photos", details: "Net Sales: $1,232", value: "32"),
                                .init(imageURL: imageURL, name: "Kentya Palm", details: "Net Sales: $800", value: "10"),
                                .init(imageURL: imageURL, name: "Love Ficus", details: "Net Sales: $599", value: "5"),
                                .init(imageURL: imageURL, name: "Bird Of Paradise", details: "Net Sales: $23.50", value: "2"),
                             ],
                             isItemsSoldRedacted: false,
                             showItemsSoldError: false)
            .previewLayout(.sizeThatFits)

        AnalyticsProductCard(itemsSold: "-",
                             delta: "0%",
                             deltaBackgroundColor: .withColorStudio(.gray, shade: .shade0),
                             deltaTextColor: .text,
                             isStatsRedacted: false,
                             showStatsError: true,
                             itemsSoldData: [],
                             isItemsSoldRedacted: false,
                             showItemsSoldError: true)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("No data")
    }
}
