import StoreDesignSystem
import SwiftUI
import struct Yosemite.ProductReport
import struct Yosemite.DashboardCard
import WooFoundation

/// View for displaying stock based on status on the dashboard.
///
struct StoreProductStockDashboardCard: View {
    @ObservedObject private var viewModel: ProductStockDashboardCardViewModel
    @State private var selectedItem: ProductReport?

    init(viewModel: ProductStockDashboardCardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        StoreDashboardCardSurface {
            VStack(alignment: .leading, spacing: StoreSpacing.s0) {
                header

                if !viewModel.analyticsEnabled {
                    StoreDashboardUnavailableAnalyticsView(title: Localization.unavailableAnalytics)
                } else if viewModel.syncingError != nil && viewModel.reports.isEmpty {
                    errorState
                } else {
                    filterBar
                        .redacted(reason: viewModel.syncingData ? [.placeholder] : [])
                        .shimmering(active: viewModel.syncingData)
                    StoreDivider()

                    Group {
                        if viewModel.reports.isNotEmpty || viewModel.syncingData {
                            stockList
                        } else {
                            emptyView
                        }
                    }
                    .redacted(reason: viewModel.syncingData && viewModel.reports.isEmpty ? [.placeholder] : [])
                    .shimmering(active: viewModel.syncingData && viewModel.reports.isEmpty)

                    timestampView
                        .renderedIf(viewModel.lastUpdatedTimestamp.isNotEmpty)
                }
            }
        }
        .sheet(item: $selectedItem, onDismiss: {
            Task {
                await viewModel.onProductDetailDismissed()
            }
        }) { item in
            ViewControllerContainer(productDetailView(for: item))
        }
    }
}

private extension StoreProductStockDashboardCard {
    var header: some View {
        StoreDashboardCardHeader(DashboardCard.CardType.stock.name,
                                 showsError: !viewModel.analyticsEnabled || viewModel.syncingError != nil) {
            StoreDashboardCardOverflowMenu(isDisabled: viewModel.syncingData) {
                Button(Localization.hideCard, action: viewModel.dismissStock)
            }
        }
    }

    var filterBar: some View {
        StoreDashboardCardFilterHeader(
            title: Localization.status,
            selectedOptionTitle: viewModel.selectedStockType.displayedName,
            options: ProductStockDashboardCardViewModel.StockType.allCases,
            isDisabled: viewModel.syncingData,
            optionTitle: { $0.displayedName },
            isSelected: { $0 == viewModel.selectedStockType },
            onSelect: selectStockType
        )
    }

    var stockList: some View {
        VStack(spacing: StoreSpacing.s0) {
            HStack {
                Text(Localization.products)
                Spacer()
                Text(Localization.stockLevels)
            }
            .storeTextStyle(.bodyMedium.emphasized)
            .foregroundStyle(.storeOnSurface)
            .padding(StorePadding.p5)

            ForEach(viewModel.reports) { element in
                StoreProductStockRow(
                    data: rowData(for: element),
                    showDivider: element != viewModel.reports.last,
                    tapHandler: {
                        ServiceLocator.analytics.track(event: .DynamicDashboard.dashboardCardInteracted(type: .stock))
                        selectedItem = element
                    }
                )
            }
        }
    }

    func rowData(for element: ProductReport) -> ProductStockRow.RowData {
        let subtitle = element.itemsSold == 0
            ? Localization.subtitleZero
            : String.pluralize(element.itemsSold,
                               singular: Localization.subtitleSingular,
                               plural: Localization.subtitlePlural)
        return ProductStockRow.RowData(
            imageURL: element.imageURL,
            name: element.name,
            subtitle: subtitle,
            accessoryText: "\(element.stockQuantity ?? 0)",
            accessoryIsError: true
        )
    }

    var emptyView: some View {
        VStack(alignment: .center, spacing: StoreSpacing.s5) {
            Image(uiImage: .productBlouseImage)
                .accessibilityHidden(true)
            Text(String.localizedStringWithFormat(Localization.emptyStateTitle,
                                                  viewModel.selectedStockType.displayedName))
                .storeTextStyle(.bodyLarge)
                .foregroundStyle(.storeOnSurface)
                .multilineTextAlignment(.center)
        }
        .padding(StorePadding.p5)
        .frame(maxWidth: .infinity)
    }

    var timestampView: some View {
        HStack(spacing: StoreSpacing.s2) {
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(.storeError)
                .renderedIf(viewModel.isShowingStaleData)
            Text(viewModel.isShowingStaleData ?
                 Localization.refreshFailedText(time: viewModel.lastUpdatedTimestamp) :
                 Localization.lastUpdatedText(time: viewModel.lastUpdatedTimestamp))
                .storeTextStyle(.bodyMedium)
                .foregroundStyle(.storeOnSurfaceVariant)
        }
        .padding(StorePadding.p5)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    var errorState: some View {
        StoreDashboardCardErrorView {
            ServiceLocator.analytics.track(event: .DynamicDashboard.cardRetryTapped(type: .stock))
            Task { await viewModel.reloadData() }
        }
    }

    func selectStockType(_ stockType: ProductStockDashboardCardViewModel.StockType) {
        ServiceLocator.analytics.track(event: .DynamicDashboard.dashboardCardInteracted(type: .stock))
        viewModel.updateStockType(stockType)
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

private extension StoreProductStockDashboardCard {
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
        static func lastUpdatedText(time: String) -> String {
            let format = NSLocalizedString(
                "productStockDashboardCard.lastUpdated",
                value: "Last Updated: %1$@",
                comment: "Time when the Stock dashboard card was last updated"
            )
            return String.localizedStringWithFormat(format, time)
        }
        static func refreshFailedText(time: String) -> String {
            let format = NSLocalizedString(
                "productStockDashboardCard.refreshFailed",
                value: "Couldn't refresh · Last Updated: %1$@",
                comment: "Message on the Stock dashboard card when a refresh fails; includes the last updated time"
            )
            return String.localizedStringWithFormat(format, time)
        }
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
    StoreProductStockDashboardCard(viewModel: .init(siteID: 123))
}
