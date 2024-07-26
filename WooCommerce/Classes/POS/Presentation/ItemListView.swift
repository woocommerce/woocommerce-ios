import SwiftUI
import protocol Yosemite.POSItem

struct ItemListView: View {
    @ScaledMetric private var scale: CGFloat = 1.0
    @ObservedObject var viewModel: ItemListViewModel
    @ObservedObject var dashboardViewModel: PointOfSaleDashboardViewModel
    @Environment(\.floatingControlAreaSize) var floatingControlAreaSize: CGSize

    init(viewModel: ItemListViewModel, dashboardViewModel: PointOfSaleDashboardViewModel) {
        self.viewModel = viewModel
        self.dashboardViewModel = dashboardViewModel
    }

    var body: some View {
        VStack {
            headerView()
            switch viewModel.state {
            case .empty(let emptyModel):
                emptyView(emptyModel)
            case .loading:
                loadingView
            case .loaded(let items):
                listView(items)
            case .error(let errorModel):
                errorView(errorModel)
            }
        }
        .refreshable {
            await viewModel.reload()
        }
        .padding(.horizontal, Constants.itemListPadding)
        .background(Color.posBackgroundGreyi3)
    }
}

/// View Helpers
///
private extension ItemListView {
    @ViewBuilder
    func headerView() -> some View {
        VStack {
            HStack {
                headerTextView
                if !viewModel.shouldShowHeaderBanner && viewModel.isHeaderBannerDismissed {
                    Spacer()
                    Button(action: {
                        openInfoBanner()
                    }, label: {
                        Image(systemName: "info.circle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: Constants.infoIconSize, height: Constants.infoIconSize)
                            .foregroundColor(Color(uiColor: .wooCommercePurple(.shade50)))
                    })
                }
            }
            if viewModel.shouldShowHeaderBanner {
                bannerCardView
                    .padding(.vertical, 16)
            }
        }
    }

    private func openInfoBanner() {
        dashboardViewModel.showSimpleProductsModal.toggle()
    }

    var bannerCardView: some View {
        HStack {
            Button(action: {
                withAnimation(.easeInOut) {
                    dashboardViewModel.showSimpleProductsModal.toggle()
                }
            }) {
                Image(systemName: "info.circle")
                    .padding(Constants.iconPadding)
                    .frame(width: Constants.infoIconSize, height: Constants.infoIconSize)
                    .foregroundColor(Color.primaryTint)
            }
            VStack(alignment: .leading) {
                Text(Localization.headerBannerTitle)
                    .font(Constants.bannerTitleFont)
                Text(Localization.headerBannerSubtitle)
                Text(Localization.headerBannerHint)
            }
            Spacer()
            VStack {
                Button(action: {
                    viewModel.dismissBanner()
                }, label: {
                    Image(systemName: "xmark.circle")
                        .frame(width: Constants.closeIconSize, height: Constants.closeIconSize)
                        .foregroundColor(.gray)
                })
                .padding(Constants.iconPadding)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: Constants.bannerHeight * scale)
        .background(Color.posBackgroundWhitei3)
    }

    var headerTextView: some View {
        Text(Localization.productSelectorTitle)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, Constants.headerPadding)
            .font(Constants.titleFont)
            .foregroundColor(Color.posPrimaryTexti3)
    }

    var loadingView: some View {
        VStack {
            Spacer()
            Text("Loading...")
            Spacer()
        }
    }

    @ViewBuilder
    func emptyView(_ content: ItemListViewModel.EmptyModel) -> some View {
        VStack {
            Spacer()
            Text(content.title)
            Text(content.subtitle)
            Button(action: {
                // TODO:
                // Redirect the merchant to the app in order to create a new product
                // https://github.com/woocommerce/woocommerce-ios/issues/13297
            }, label: {
                Text(content.buttonText)}
            )
            Text(content.hint)
            Spacer()
        }
    }

    @ViewBuilder
    func listView(_ items: [POSItem]) -> some View {
        ScrollView {
            VStack {
                ForEach(items, id: \.productID) { item in
                    Button(action: {
                        viewModel.select(item)
                    }, label: {
                        ItemCardView(item: item)
                    })
                }
            }
            .padding(.bottom, floatingControlAreaSize.height)
        }
    }

    @ViewBuilder
    func errorView(_ content: ItemListViewModel.ErrorModel) -> some View {
        VStack {
            Spacer()
            Text(content.title)
            Button(action: {
                Task {
                    await viewModel.populatePointOfSaleItems()
                }
            }, label: {
                Text(content.buttonText)
            })
            Spacer()
        }
    }
}

/// Constants
///
private extension ItemListView {
    enum Constants {
        static let titleFont: Font = .system(size: 40, weight: .bold, design: .default)
        static let bannerTitleFont: Font = .system(size: 26, weight: .bold, design: .default)
        static let bannerHeight: CGFloat = 120
        static let infoIconSize: CGFloat = 24
        static let closeIconSize: CGFloat = 26
        static let iconPadding: CGFloat = 24
        static let headerPadding: CGFloat = 8
        static let itemListPadding: CGFloat = 32
    }

    enum Localization {
        static let productSelectorTitle = NSLocalizedString(
            "pos.itemlistview.productSelectorTitle",
            value: "Products",
            comment: "Title of the Point of Sale product selector"
        )
        static let headerBannerTitle = NSLocalizedString(
            "pos.itemlistview.headerBannerTitle",
            value: "Showing simple products only",
            comment: "Title of the product selector header banner, which explains current POS limitations"
        )
        static let headerBannerSubtitle = NSLocalizedString(
            "pos.itemlistview.headerBannerSubtitle",
            value: "Only simple physical products are available with POS right now.",
            comment: "Subtitle of the product selector header banner, which explains current POS limitations"
        )
        static let headerBannerHint = NSLocalizedString(
            "pos.itemlistview.headerBannerHint",
            value: "Other product types, such as variable and virtual, will become available in future updates.",
            comment: "Additional text within the product selector header banner, which explains current POS limitations"
        )
    }
}

#if DEBUG
#Preview {
    ItemListView(viewModel: ItemListViewModel(itemProvider: POSItemProviderPreview()), dashboardViewModel: PointOfSaleDashboardViewModel(itemProvider: POSItemProviderPreview(), cardPresentPaymentService: CardPresentPaymentPreviewService(), orderService: POSOrderPreviewService(), currencyFormatter: .init(currencySettings: .init()), totalsViewModel: TotalsViewModel(orderService: POSOrderPreviewService(), cardPresentPaymentService: CardPresentPaymentPreviewService(), currencyFormatter: .init(currencySettings: .init()), paymentState: .acceptingCard, isSyncingOrder: false), cartViewModel: CartViewModel()))
}
#endif
