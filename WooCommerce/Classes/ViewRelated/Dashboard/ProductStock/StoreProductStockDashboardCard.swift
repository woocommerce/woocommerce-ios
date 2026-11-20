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
    typealias Localization = ProductStockDashboardCard.Localization

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

#Preview {
    StoreProductStockDashboardCard(viewModel: .init(siteID: 123))
}
