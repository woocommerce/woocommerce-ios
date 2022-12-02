import SwiftUI

/// Products Card on the Analytics Hub
///
struct AnalyticsProductCard: View {

    let viewModel: AnalyticsProductCardViewModel

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
                Text(viewModel.itemsSold)
                    .titleStyle()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .redacted(reason: viewModel.isRedacted ? .placeholder : [])
                    .shimmering(active: viewModel.isRedacted)

                DeltaTag(value: viewModel.delta, backgroundColor: viewModel.deltaBackgroundColor)
                    .redacted(reason: viewModel.isRedacted ? .placeholder : [])
                    .shimmering(active: viewModel.isRedacted)
            }

            if viewModel.showSyncError {
                Text(Localization.noProducts)
                    .foregroundColor(Color(.text))
                    .subheadlineStyle()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, Layout.columnSpacing)
            }

            TopPerformersView(itemTitle: Localization.title.localizedCapitalized, valueTitle: Localization.itemsSold, rows: viewModel.itemsSoldData)
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
        static let noProducts = NSLocalizedString("Unable to load product analytics",
                                                  comment: "Text displayed when there is an error loading product stats data.")
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
        AnalyticsProductCard(viewModel: .init(itemsSold: "2,234",
                                              delta: "+23%",
                                              deltaBackgroundColor: .withColorStudio(.green, shade: .shade50),
                                              itemsSoldData: [
                                                .init(imageURL: imageURL, name: "Tabletop Photos", details: "Net Sales: $1,232", value: "32"),
                                                .init(imageURL: imageURL, name: "Kentya Palm", details: "Net Sales: $800", value: "10"),
                                                .init(imageURL: imageURL, name: "Love Ficus", details: "Net Sales: $599", value: "5"),
                                                .init(imageURL: imageURL, name: "Bird Of Paradise", details: "Net Sales: $23.50", value: "2"),
                                              ],
                                              isRedacted: false,
                                              showSyncError: false))
            .previewLayout(.sizeThatFits)

        AnalyticsProductCard(viewModel: .init(itemsSold: "-",
                                              delta: "0%",
                                              deltaBackgroundColor: .withColorStudio(.gray, shade: .shade0),
                                              itemsSoldData: [],
                                              isRedacted: false,
                                              showSyncError: true))
            .previewLayout(.sizeThatFits)
            .previewDisplayName("No data")
    }
}
