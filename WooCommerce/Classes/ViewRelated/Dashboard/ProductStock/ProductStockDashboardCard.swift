import Kingfisher
import SwiftUI
import struct Yosemite.DashboardCard

/// View for displaying stock based on status on the dashboard.
///
struct ProductStockDashboardCard: View {
    @ObservedObject private var viewModel: ProductStockDashboardCardViewModel
    @ScaledMetric private var scale: CGFloat = 1.0

    init(viewModel: ProductStockDashboardCardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.padding) {
            header
                .padding(.horizontal, Layout.padding)

            filterBar
                .padding(.horizontal, Layout.padding)
                .redacted(reason: viewModel.syncingData ? [.placeholder] : [])
                .shimmering(active: viewModel.syncingData)

            Divider()

            stockList
                .padding(.horizontal, Layout.padding)
                .redacted(reason: viewModel.syncingData ? [.placeholder] : [])
                .shimmering(active: viewModel.syncingData)
        }
        .padding(.vertical, Layout.padding)
        .background(Color(.listForeground(modal: false)))
        .clipShape(RoundedRectangle(cornerSize: Layout.cornerSize))
        .padding(.horizontal, Layout.padding)
    }
}

private extension ProductStockDashboardCard {
    var header: some View {
        HStack {
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(Color.secondary)
                .headlineStyle()
                .renderedIf(viewModel.syncingError != nil)
            Text(DashboardCard.CardType.stock.name)
                .headlineStyle()
            Spacer()
            Menu {
                Button(Localization.hideCard) {
                    viewModel.dismissStock()
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(Color.secondary)
                    .padding(.leading, Layout.padding)
                    .padding(.vertical, Layout.hideIconVerticalPadding)
            }
            .disabled(viewModel.syncingData)
        }
    }

    var filterBar: some View {
        HStack {
            Text(Localization.status)
                .foregroundStyle(Color.primaryText)
                .subheadlineStyle()
            Text(viewModel.selectedStockType.displayedName)
                .subheadlineStyle()
            Spacer()
            Menu {
                ForEach(ProductStockDashboardCardViewModel.StockType.allCases) { stockType in
                    Button {
                        viewModel.updateStockType(stockType)
                    } label: {
                        SelectableItemRow(title: stockType.displayedName, selected: stockType == viewModel.selectedStockType)
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
                    .foregroundStyle(Color(.secondaryLabel))
            }

        }
    }

    var stockList: some View {
        VStack(spacing: Layout.padding) {
            HStack {
                Text(Localization.products)
                    .subheadlineStyle()
                    .fontWeight(.semibold)
                Spacer()
                Text(Localization.stockLevels)
                    .subheadlineStyle()
                    .fontWeight(.semibold)
            }
            ForEach(Array(viewModel.stock.enumerated()), id: \.element) { (index, element) in
                HStack(alignment: .top) {
                    // Thumbnail image
                    KFImage(element.thumbnailURL)
                        .placeholder { Image(uiImage: .productPlaceholderImage)
                                .foregroundColor(Color(.listIcon))
                        }
                        .resizable()
                        .frame(width: Layout.thumbnailSize * scale,
                               height: Layout.thumbnailSize * scale)
                        .clipShape(RoundedRectangle(cornerSize: Layout.thumbnailCornerSize))

                    // Details
                    VStack {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading) {
                                Text(element.productName)
                                    .bodyStyle()
                                Text(String(format: Localization.subtitle,
                                            element.itemsSoldLast30Days))
                                    .subheadlineStyle()
                            }
                            Spacer()
                            Text("\(element.stockQuantity)")
                                .foregroundStyle(Color(.error))
                                .bodyStyle()
                                .fontWeight(.semibold)
                        }
                        Divider()
                            .renderedIf(index < viewModel.stock.count - 1)
                    }
                }
            }
        }
    }
}

private extension ProductStockDashboardCard {
    enum Layout {
        static let padding: CGFloat = 16
        static let cornerSize = CGSize(width: 8.0, height: 8.0)
        static let hideIconVerticalPadding: CGFloat = 8
        static let thumbnailSize: CGFloat = 40
        static let thumbnailCornerSize = CGSize(width: 4.0, height: 4.0)
    }

    enum Localization {
        static let hideCard = NSLocalizedString(
            "productStockDashboardCard.hideCard",
            value: "Hide Stock",
            comment: "Menu item to dismiss the Stock section on the My Store screen"
        )
        static let status = NSLocalizedString(
            "productStockDashboardCard.status",
            value: "Status",
            comment: "Header label on the Stock section on the My Store screen"
        )
        static let products = NSLocalizedString(
            "productStockDashboardCard.products",
            value: "Products",
            comment: "Header label on the Stock section on the My Store screen"
        )
        static let stockLevels = NSLocalizedString(
            "productStockDashboardCard.stockLevels",
            value: "Stock levels",
            comment: "Header label on the Stock section on the My Store screen"
        )
        static let subtitle = NSLocalizedString(
            "productStockDashboardCard.item.subtitle",
            value: "%1$d items sold last 30 days",
            comment: "Subtitle for the stock items on the Stock section on the My Store screen. " +
            "Reads as: 10 items sold last 30 days"
        )
    }
}

#Preview {
    ProductStockDashboardCard(viewModel: .init(siteID: 123))
}
