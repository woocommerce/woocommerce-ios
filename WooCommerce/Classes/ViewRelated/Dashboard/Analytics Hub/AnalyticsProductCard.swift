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

    /// Indicates if the values should be hidden (for loading state)
    ///
    let isRedacted: Bool

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
                    .redacted(reason: isRedacted ? .placeholder : [])
                    .shimmering(active: isRedacted)

                DeltaTag(value: delta, backgroundColor: deltaBackgroundColor)
                    .redacted(reason: isRedacted ? .placeholder : [])
                    .shimmering(active: isRedacted)
            }

            let imageURL = URL(string: "https://s0.wordpress.com/i/store/mobile/plans-premium.png")
            TopPerformersView(itemTitle: "Products",
                              valueTitle: "Items Sold",
                              rows: [
                                .init(imageURL: imageURL, name: "Tabletop Photos", details: "Net Sales: $1,232", value: "32"),
                                .init(imageURL: imageURL, name: "Kentya Palm", details: "Net Sales: $800", value: "10"),
                                .init(imageURL: imageURL, name: "Love Ficus", details: "Net Sales: $599", value: "5"),
                                .init(imageURL: imageURL, name: "Bird Of Paradise", details: "Net Sales: $23.50", value: "2")
                              ])
            .padding(.top, Layout.columnSpacing)
        }
        .padding(Layout.cardPadding)
    }
}

// MARK: Constants
private extension AnalyticsProductCard {
    enum Localization {
        static let title = NSLocalizedString("Products", comment: "Title for the products card on the analytics hub screen.").localizedUppercase
        static let itemsSold = NSLocalizedString("Items Sold", comment: "Title for the items sold column on the products card on the analytics hub screen.")
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
        AnalyticsProductCard(itemsSold: "2,234",
                             delta: "+23%",
                             deltaBackgroundColor: .withColorStudio(.green, shade: .shade50),
                             isRedacted: false)
            .previewLayout(.sizeThatFits)
    }
}
