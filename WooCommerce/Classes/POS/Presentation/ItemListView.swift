import SwiftUI
import enum Yosemite.POSItem
import protocol Yosemite.POSOrderableItem

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
            HStack {
                POSHeaderTitleView(title: Localization.title)
                if !shouldShowHeaderBanner {
                    Spacer()
                    Button(action: {
                        ServiceLocator.analytics.track(.pointOfSaleSimpleProductsExplanationDialogShown)
                        showSimpleProductsModal = true
                    }, label: {
                        Text(Image(systemName: "info.circle"))
                            .font(.posButtonSymbolLarge)
                    })
                    .foregroundColor(.posOnSurface)
                    .padding(.trailing, Constants.infoIconPadding)
                }
            }
            if !dynamicTypeSize.isAccessibilitySize, shouldShowHeaderBanner {
                bannerCardView
                    .padding(.horizontal, Constants.bannerCardPadding)
            }
        }
    }

    var bannerCardView: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack {
                Spacer()
                Text(Image(systemName: "info.circle"))
                    .font(.posButtonSymbolLarge)
                    .padding(Constants.iconPadding)
                    .foregroundColor(Color.posOnSurface)
                    .accessibilityHidden(true)
                Spacer()
            }
            VStack(alignment: .leading, spacing: Constants.bannerTitleSpacing) {
                Text(headerBannerTitle)
                    .font(Constants.bannerTitleFont)
                    .accessibilityAddTraits(.isHeader)
                VStack(alignment: .leading, spacing: Constants.bannerTextSpacing) {
                    Text(headerBannerSubtitle)
                    bannerHintAndLearnMoreText
                }
                .font(Constants.bannerSubtitleFont)
                .lineSpacing(Constants.bannerTextSpacing)
                .accessibilityElement(children: .combine)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, Constants.bannerVerticalPadding)
            VStack {
                Button(action: {
                    isHeaderBannerDismissed = true
                }, label: {
                    Text(Image(systemName: "xmark"))
                        .font(.posButtonSymbolSmall)
                        .foregroundColor(Color.posOnSurfaceVariantLowest)
                        .accessibilityLabel(Localization.dismissBannerAccessibilityLabel)
                })
                .padding(Constants.iconPadding)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.posSurfaceBright)
        .cornerRadius(Constants.bannerCornerRadius)
        .posShadow(.medium)
        .accessibilityAddTraits(.isButton)
        .onTapGesture {
            showSimpleProductsModal = true
        }
        .padding(.bottom, Constants.bannerCardPadding)
    }

    private var bannerHintAndLearnMoreText: Text {
        Text(headerBannerHint + " ") +
        Text(Localization.headerBannerLearnMoreHint)
            .font(POSFontStyle.posBodySmallBold.font())
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
        static let bannerTitleFont: POSFontStyle = .posBodyLargeBold
        static let bannerSubtitleFont: POSFontStyle = .posBodySmallRegular()
        static let bannerCornerRadius: CGFloat = POSCornerRadiusStyle.medium.value
        static let bannerVerticalPadding: CGFloat = 26
        static let bannerTextSpacing: CGFloat = 4
        static let bannerTitleSpacing: CGFloat = 8
        static let infoIconPadding: CGFloat = 16
        static let iconPadding: CGFloat = 26
        static let itemListPadding: CGFloat = 16
        static let bannerCardPadding: CGFloat = 16
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

        static let dismissBannerAccessibilityLabel = NSLocalizedString(
            "pos.itemListView.headerBanner.dismiss.button.accessibiltyLabel",
            value: "Dismiss",
            comment: "Accessibility label for button to dismiss the product selector header banner. " +
            "The banner explains current POS limitations. Tapping the button prevents it being shown again."
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
