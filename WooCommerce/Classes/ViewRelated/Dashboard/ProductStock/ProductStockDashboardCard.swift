import Kingfisher
import SwiftUI
import struct Yosemite.ProductReport
import struct Yosemite.DashboardCard
import enum Networking.DotcomError

/// View for displaying stock based on status on the dashboard.
///
struct ProductStockDashboardCard: View {
    @ObservedObject private var viewModel: ProductStockDashboardCardViewModel
    @ScaledMetric private var scale: CGFloat = 1.0
    @State private var showingSupportForm = false
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

            if let error = viewModel.syncingError {
                if error as? DotcomError == .noRestRoute {
                    contentUnavailableView
                        .padding(.horizontal, Layout.padding)
                } else {
                    DashboardCardErrorView(onRetry: {
                        ServiceLocator.analytics.track(event: .DynamicDashboard.cardRetryTapped(type: .stock))
                        Task {
                            await viewModel.reloadData()
                        }
                    })
                    .padding(.horizontal, Layout.padding)
                }
            }

            Group {
                if viewModel.reports.isNotEmpty {
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
        .sheet(isPresented: $showingSupportForm) {
            supportForm
        }
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
                    .foregroundStyle(Color.primaryText)
                    .subheadlineStyle()
                Text(viewModel.selectedStockType.displayedName)
                    .subheadlineStyle()
            }
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
            ForEach(viewModel.reports) { element in
                Button {
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
                                Text("\(element.stockQuantity)")
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

    var contentUnavailableView: some View {
        VStack(alignment: .center, spacing: Layout.padding) {
            Image(uiImage: .noStoreImage)
            Text(Localization.ContentUnavailable.title)
                .headlineStyle()
            Text(Localization.ContentUnavailable.details)
                .bodyStyle()
                .multilineTextAlignment(.center)
            Button(Localization.ContentUnavailable.buttonTitle) {
                showingSupportForm = true
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .frame(maxWidth: .infinity)
    }

    var supportForm: some View {
        NavigationStack {
            SupportForm(isPresented: $showingSupportForm,
                        viewModel: SupportFormViewModel())
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Localization.ContentUnavailable.done) {
                        showingSupportForm = false
                    }
                }
            }
        }
    }

    func productDetailView(for item: ProductReport) -> UIViewController {
        let loaderViewController = ProductLoaderViewController(model: .product(productID: item.productID),
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
        enum ContentUnavailable {
            static let title = NSLocalizedString(
                "productStockDashboardCard.contentUnavailable.title",
                value: "Unable to load stock report",
                comment: "Title when we can't load stock report because user is on a deprecated WooCommerce Version"
            )
            static let details = NSLocalizedString(
                "productStockDashboardCard.contentUnavailable.details",
                value: "Make sure you are running the latest version of WooCommerce on your site" +
                " and enabling Analytics in WooCommerce Settings.",
                comment: "Text that explains how to update WooCommerce to get the latest stats"
            )
            static let buttonTitle = NSLocalizedString(
                "productStockDashboardCard.contentUnavailable.buttonTitle",
                value: "Still need help? Contact us",
                comment: "Button title to contact support to get help with deprecated stats module"
            )
            static let done = NSLocalizedString(
                "productStockDashboardCard.contentUnavailable.dismissSupport",
                value: "Done",
                comment: "Button to dismiss the support form from the Dashboard stock card error screen."
            )
        }
    }
}

#Preview {
    ProductStockDashboardCard(viewModel: .init(siteID: 123))
}
