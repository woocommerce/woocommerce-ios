import SwiftUI
import enum Yosemite.POSItem
import protocol Yosemite.POSOrderableItem
import enum Yosemite.CouponAction

@available(iOS 17.0, *)
struct ItemListView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @Environment(PointOfSaleAggregateModel.self) private var posModel

    @State private var showSimpleProductsModal: Bool = false
    private var itemListState: ItemListState {
        posModel.itemsViewState.itemsStack.root
    }

    @AppStorage(BannerState.isSimpleProductsOnlyBannerDismissedKey)
    private var isHeaderBannerDismissed: Bool = false
    
    private var shouldShowCoupons: Bool {
        ServiceLocator.featureFlagService.isFeatureFlagEnabled(.enableCouponsInPointOfSale)
    }
    
    @State private var coupons: [CouponDetailsViewModel] = []
    
    // (!) There is no general Coupon object on WooCommece, we have network and storage models, then implementation details for the app use cases.
    private func loadAllCoupons() {
        let siteID = ServiceLocator.stores.sessionManager.defaultStoreID ?? 0
        
        let action = CouponAction.loadAllCouponsFromRemote(siteID: siteID, pageNumber: 1, pageSize: 25, onCompletion: { result in
            switch result {
            case .failure:
                // TODO: Existing events would need POS decoration
                ServiceLocator.analytics.track(.couponsLoadedFailed)
                break
            case let .success(couponsResult):
                couponsResult.map {
                    coupons.append(CouponDetailsViewModel(coupon: $0))
                }
                ServiceLocator.analytics.track(.couponsLoaded)
            }
        })
        ServiceLocator.stores.dispatch(action)
    }

    var body: some View {
        NavigationStack {
            VStack {
                headerView
                switch itemListState {
                case .loading(let items),
                        .loaded(let items, _),
                        .inlineError(let items, _):
                    listView(items)
                case .error:
                    // Currently unused, but this will show errors that are displayed inline with previously
                    // loaded items, e.g. when loading a new page or refreshing.
                    EmptyView()
                }
            }
            .navigationDestination(for: POSItem.self, destination: { item in
                childListView(parentItem: item)
            })
            .background(Color.posSurface)
        }
        .accessibilityElement(children: .contain)
        .posModal(isPresented: $showSimpleProductsModal) {
            SimpleProductsOnlyInformation(isPresented: $showSimpleProductsModal)
        }
    }
}

/// View Helpers
///
@available(iOS 17.0, *)
private extension ItemListView {
    @ViewBuilder
    var headerView: some View {
        VStack {
            POSPageHeaderView(title: Localization.title, trailingContent: {
                HStack(spacing: 10) {
                    Button(action: {
                        // (!) We do not have a generic event for tracking loading coupons, many existing events are usecase dependent
                        loadAllCoupons()
                    }, label: {
                        Text("Show coupons (\(coupons.count))")
                            .font(.posButtonSymbolSmall)
                            .foregroundStyle(Color.posOnSurface)
                            .padding(Constants.infoIconInset)
                    })
                    Button(action: {
                        showSimpleProductsModal = true
                    }, label: {
                        Text(Image(systemName: "info.circle"))
                            .font(.posButtonSymbolLarge)
                            .foregroundStyle(Color.posOnSurface)
                            .padding(Constants.infoIconInset)
                    })
                    .renderedIf(shouldShowCoupons)
                }
            })
            if !dynamicTypeSize.isAccessibilitySize, shouldShowHeaderBanner {
                bannerCardView
                    .padding(.horizontal, Constants.bannerCardPadding)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            }
        }
    }

    var bannerCardView: some View {
        POSNoticeView(
            title: headerBannerTitle,
            icon: Image(systemName: "info.circle"),
            onDismiss: {
                isHeaderBannerDismissed = true
            },
            onTap: {
                showSimpleProductsModal = true
            }
        ) {
            VStack(alignment: .leading, spacing: Constants.bannerTextSpacing) {
                Text(headerBannerSubtitle)
                bannerHintAndLearnMoreText
            }
        }
        .padding(.bottom, Constants.bannerCardPadding)
    }

    private var bannerHintAndLearnMoreText: some View {
        Text("\(headerBannerHint) \(Localization.headerBannerLearnMoreHint)")
            .font(.posBodySmallBold)
            .foregroundColor(Color(.posPrimary))
    }

    @ViewBuilder
    func listView(_ items: [POSItem]) -> some View {
        ItemList(state: itemListState) {
            if dynamicTypeSize.isAccessibilitySize, shouldShowHeaderBanner {
                bannerCardView
            }
        }
        .refreshable {
            ServiceLocator.analytics.track(.pointOfSaleProductsPullToRefresh)
            await posModel.refreshItems(base: .root)
        }
    }

    @ViewBuilder
    func childListView(parentItem: POSItem) -> some View {
        switch parentItem {
        case let .variableParentProduct(parentProduct):
            ChildItemList(parentItem: parentItem, title: parentProduct.name)
        default:
            EmptyView()
        }
    }
}

@available(iOS 17.0, *)
private extension ItemListView {
    var shouldShowHeaderBanner: Bool {
        itemListState.eligibleToShowSimpleProductsBanner && !isHeaderBannerDismissed
    }
}

private extension ItemListState {
    var eligibleToShowSimpleProductsBanner: Bool {
        switch self {
        case .loading,
                .loaded,
                .inlineError:
            return true
        case .error:
            return false
        }
    }
}

/// Constants
///
@available(iOS 17.0, *)
private extension ItemListView {
    enum Constants {
        static let infoIconInset: EdgeInsets = .init(top: 0, leading: 6, bottom: 0, trailing: 6)
        static let bannerCardPadding: CGFloat = POSPadding.medium
        static let bannerTextSpacing: CGFloat = POSSpacing.xSmall
    }

    enum BannerState {
        static let isSimpleProductsOnlyBannerDismissedKey = "isSimpleProductsOnlyBannerDismissed"
    }

    var headerBannerTitle: String {
        Localization.headerBannerTitleSimpleAndVariable
    }

    var headerBannerSubtitle: String {
        Localization.headerBannerSubtitleSimpleAndVariable
    }

    var headerBannerHint: String {
        Localization.headerBannerHintSimpleAndVariable
    }

    enum Localization {
        static let title = NSLocalizedString(
            "pos.itemlistview.title",
            value: "Products",
            comment: "Title at the top of the Point of Sale product selector screen."
        )

        static let headerBannerTitleSimpleAndVariable = NSLocalizedString(
            "pos.itemlistview.headerBanner.title.simpleAndVariable",
            value: "Showing simple and variable products only",
            comment: "Title of the product selector header banner, which explains current POS limitations"
        )

        static let headerBannerSubtitleSimpleAndVariable = NSLocalizedString(
            "pos.itemlistview.headerBanner.subtitle.simpleAndVariable",
            value: "Only simple and variable non-downloadable products can be used with POS right now.",
            comment: "Subtitle of the product selector header banner, which explains current POS limitations"
        )

        static let headerBannerHintSimpleAndVariable = NSLocalizedString(
            "pos.itemlistview.headerBanner.hint.simpleAndVariable",
            value: "Other product types will become available in future updates.",
            comment: "Additional text within the product selector header banner, which explains current POS limitations"
        )

        static let headerBannerLearnMoreHint = NSLocalizedString(
            "pos.itemlistview.headerBanner.learnMoreHint",
            value: "Learn More",
            comment: "Link to more information within the product selector header banner, which explains current POS limitations"
        )
    }
}

#if DEBUG

@available(iOS 17.0, *)
#Preview("Loaded with all product types") {
    let itemsController = PointOfSalePreviewItemsController()
    Task { @MainActor in
        await itemsController.loadItems(base: .root)
    }
    let posModel = PointOfSaleAggregateModel(
        itemsController: itemsController,
        cardPresentPaymentService: CardPresentPaymentPreviewService(),
        orderController: PointOfSalePreviewOrderController(),
        collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalytics())
    return ItemListView()
        .environment(posModel)
}

@available(iOS 17.0, *)
#Preview("Loading") {
    let posModel = PointOfSaleAggregateModel(
        itemsController: PointOfSalePreviewItemsController(),
        cardPresentPaymentService: CardPresentPaymentPreviewService(),
        orderController: PointOfSalePreviewOrderController(),
        collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalytics())
    return ItemListView()
        .environment(posModel)
}

#endif
