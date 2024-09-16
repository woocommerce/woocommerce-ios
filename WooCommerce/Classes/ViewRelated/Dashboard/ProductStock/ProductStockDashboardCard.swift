import Kingfisher
import SwiftUI
import struct Yosemite.ProductReport
import struct Yosemite.DashboardCard

/// View for displaying stock based on status on the dashboard.
///
struct ProductStockDashboardCard: View {
    @ObservedObject private var viewModel: ProductStockDashboardCardViewModel
    @ScaledMetric private var scale: CGFloat = 1.0
    @State private var selectedItem: ProductReport?

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

            if !viewModel.analyticsEnabled {
                UnavailableAnalyticsView(title: Localization.unavailableAnalytics)
                    .padding(.horizontal, Layout.padding)
            } else if viewModel.syncingError != nil {
                DashboardCardErrorView(onRetry: {
                    ServiceLocator.analytics.track(event: .DynamicDashboard.cardRetryTapped(type: .stock))
                    Task {
                        await viewModel.reloadData()
                    }
                })
                .padding(.horizontal, Layout.padding)
            }

            Group {
                if viewModel.reports.isNotEmpty || viewModel.syncingData {
                    stockList
                } else {
                    emptyView
                }
            }
            .padding(.horizontal, Layout.padding)
            .redacted(reason: viewModel.syncingData ? [.placeholder] : [])
            .shimmering(active: viewModel.syncingData)
            .renderedIf(viewModel.syncingError == nil)
        }
        .padding(.vertical, Layout.padding)
        .background(Color(.listForeground(modal: false)))
        .clipShape(RoundedRectangle(cornerSize: Layout.cornerSize))
        .padding(.horizontal, Layout.padding)
        .sheet(item: $selectedItem) { item in
            ViewControllerContainer(productDetailView(for: item))
        }
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
            AdaptiveStack(horizontalAlignment: .leading) {
                Text(Localization.status)
                    .foregroundStyle(Color.primary)
                    .subheadlineStyle()
                Text(viewModel.selectedStockType.displayedName)
                    .subheadlineStyle()
            }
            Spacer()
            Menu {
                ForEach(ProductStockDashboardCardViewModel.StockType.allCases) { stockType in
                    Button {
                        ServiceLocator.analytics.track(event: .DynamicDashboard.dashboardCardInteracted(type: .stock))
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
            ForEach(viewModel.reports) { element in
                Button {
                    ServiceLocator.analytics.track(event: .DynamicDashboard.dashboardCardInteracted(type: .stock))

                    selectedItem = element
                } label: {
                    HStack(alignment: .top) {
                        // Thumbnail image
                        KFImage(element.imageURL)
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
                                    Text(element.name)
                                        .bodyStyle()
                                        .multilineTextAlignment(.leading)
                                    Text(element.itemsSold == 0 ? Localization.subtitleZero :
                                            String.pluralize(element.itemsSold,
                                                                  singular: Localization.subtitleSingular,
                                                                  plural: Localization.subtitlePlural))
                                    .subheadlineStyle()
                                    .multilineTextAlignment(.leading)
                                }
                                Spacer()
                                Text("\(element.stockQuantity ?? 0)")
                                    .foregroundStyle(Color(.error))
                                    .bodyStyle()
                                    .fontWeight(.semibold)
                            }
                            Divider()
                                .renderedIf(element != viewModel.reports.last)
                        }
                    }
                }
            }
        }
    }

    var emptyView: some View {
        VStack(alignment: .center, spacing: Layout.padding) {
            Image(uiImage: .noStoreImage)
            Text(String(format: Localization.emptyStateTitle,
                        viewModel.selectedStockType.displayedName))
                .subheadlineStyle()
        }
        .padding(Layout.padding)
        .frame(maxWidth: .infinity)
    }

    func productDetailView(for item: ProductReport) -> UIViewController {
        let model: ProductLoaderViewController.Model = {
            if let variationID = item.variationID {
                .productVariation(productID: item.productID, variationID: variationID)
            } else {
                .product(productID: item.productID)
            }
        }()
        let loaderViewController = ProductLoaderViewController(model: model,
                                                               siteID: viewModel.siteID,
                                                               forceReadOnly: false)
        return WooNavigationController(rootViewController: loaderViewController)
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
        static let subtitleSingular = NSLocalizedString(
            "productStockDashboardCard.item.subtitle.singular",
            value: "%1$d item sold last 30 days",
            comment: "Subtitle in singular mode for the stock items on the Stock section on the My Store screen. " +
            "Reads as: 1 item sold last 30 days"
        )
        static let subtitlePlural = NSLocalizedString(
            "productStockDashboardCard.item.subtitle.plural",
            value: "%1$d items sold last 30 days",
            comment: "Subtitle in plural mode for the stock items on the Stock section on the My Store screen. " +
            "Reads as: 10 items sold last 30 days"
        )
        static let subtitleZero = NSLocalizedString(
            "productStockDashboardCard.item.subtitle.zero",
            value: "No item sold last 30 days",
            comment: "Subtitle for the stock items with no items sold on the Stock section on the My Store screen."
        )
        static let emptyStateTitle = NSLocalizedString(
            "productStockDashboardCard.emptyStateTitle",
            value: "No item found with %1$@ status",
            comment: "Text on the empty state of the Stock section on the My Store screen. " +
            "Reads as: No item found with Out of stock status"
        )
        static let unavailableAnalytics = NSLocalizedString(
            "productStockDashboardCard.unavailableAnalyticsView.title",
            value: "Unable to display your store's stock analytics",
            comment: "Title when the Stock card is disabled because the analytics feature is unavailable"
        )
    }
}

#Preview {
    ProductStockDashboardCard(viewModel: .init(siteID: 123))
}
