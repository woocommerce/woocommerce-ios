import SwiftUI
import enum Yosemite.POSItem
import protocol Yosemite.POSOrderableItem
import struct Yosemite.POSParentProduct

struct ItemListView: View {
    @Environment(\.floatingControlAreaSize) var floatingControlAreaSize: CGSize
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @EnvironmentObject var posModel: PointOfSaleAggregateModel

    @State private var path: [POSItem] = []

    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                switch posModel.itemListState {
                case .initialLoading, .empty, .error:
                    // These cases are handled directly in the dashboard, we do not render
                    // a specific view within the ItemListView to handle them
                    EmptyView()
                case .loading(_, _, _),
                        .loaded(_, _, _):
                    ItemList(rootItem: nil, showChildren: { item in
                        path.append(item)
                    })
                    .refreshable {
                        await posModel.reload()
                    }
                }
            }
            .navigationDestination(for: POSItem.self, destination: { item in
                ItemList(rootItem: item, showChildren: { item in
                    path.append(item)
                })
                .background(Color.posPrimaryBackground)
                .toolbar(.hidden, for: .navigationBar)
            })
            .background(Color.posPrimaryBackground)
            .accessibilityElement(children: .contain)
        }
    }
}

// Hmmm don't love this but it works to keep the back navigation swipe even though we hide the default nav bar.
// It may have implications on the rest of the app. If we can scope it down to POS only, that would be better.
extension UINavigationController {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}

/// View Helpers
///
private extension ItemList {
    @ViewBuilder
    func headerView(context: NavigationContext = .root) -> some View {
        VStack {
            HStack {
                if case .child = context {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Text("\(Image(systemName: "chevron.backward")) Back")
                            .font(.posTitleRegular)
                    }

                    Spacer()
                }
                POSHeaderTitleView(context: context)
                if !shouldShowHeaderBanner {
                    Spacer()
                    Button(action: {
                        showSimpleProductsModal = true
                    }, label: {
                        Image(systemName: "info.circle")
                            .font(.posTitleRegular)
                    })
                    .foregroundColor(.posPrimaryText)
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
                Image(systemName: "info.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Constants.bannerInfoIconSize, height: Constants.bannerInfoIconSize)
                    .padding(Constants.iconPadding)
                    .foregroundColor(Color(uiColor: .wooCommercePurple(.shade30)))
                    .accessibilityHidden(true)
                Spacer()
            }
            VStack(alignment: .leading, spacing: Constants.bannerTitleSpacing) {
                Text(Localization.headerBannerTitle)
                    .font(Constants.bannerTitleFont)
                    .accessibilityAddTraits(.isHeader)
                VStack(alignment: .leading, spacing: Constants.bannerTextSpacing) {
                    Text(Localization.headerBannerSubtitle)
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
                    Image(systemName: "xmark")
                        .font(.posBodyRegular)
                        .foregroundColor(Color.posTertiaryText)
                        .accessibilityLabel(Localization.dismissBannerAccessibilityLabel)
                })
                .padding(Constants.iconPadding)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.posSecondaryBackground)
        .cornerRadius(Constants.bannerCornerRadius)
        .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)
        .accessibilityAddTraits(.isButton)
        .onTapGesture {
            showSimpleProductsModal = true
        }
        .padding(.bottom, Constants.bannerCardPadding)
    }

    private var bannerHintAndLearnMoreText: Text {
        Text(Localization.headerBannerHint + " ") +
        Text(Localization.headerBannerLearnMoreHint)
            .font(POSFontStyle.posDetailEmphasized.font())
            .foregroundColor(Color(.accent))
    }
}

private extension ItemList {
    var shouldShowHeaderBanner: Bool {
        posModel.itemListState.eligibleToShowSimpleProductsBanner && !isHeaderBannerDismissed
    }
}

private extension ItemListState {
    var eligibleToShowSimpleProductsBanner: Bool {
        switch self {
        case .loading,
                .loaded:
            return true
        case .empty,
            .initialLoading,
            .error:
            return false
        }
    }
}

struct GhostItemCardView: View {
    @ScaledMetric private var scale: CGFloat = 1.0

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .frame(width: Constants.productCardSize * scale, height: Constants.productCardSize * scale)
            HStack {
                Rectangle()
                    .foregroundColor(Constants.textForegroundColor)
                    .frame(width: Constants.textWidth * 2 * scale, height: Constants.textHeight * scale)
                    .padding(.horizontal)
                Spacer()
                Rectangle()
                    .foregroundColor(Constants.textForegroundColor)
                    .frame(width: Constants.textWidth * scale, height: Constants.textHeight * scale)
                    .padding(.horizontal)
            }
            .frame(height: Constants.productCardSize * scale)
        }
        .overlay {
            RoundedRectangle(cornerRadius: Constants.cornerRadius)
        }
        .foregroundColor(Constants.cardForegroundColor)
        .shimmering()
    }
}

private extension GhostItemCardView {
    enum Constants {
        static let cornerRadius: CGFloat = 8
        static let cardForegroundColor: Color = Color.gray.opacity(0.5)
        static let textForegroundColor: Color = Color.gray.opacity(0.8)
        static let productCardSize: CGFloat = 112
        static let textWidth: CGFloat = 112
        static let textHeight: CGFloat = 32
    }
}

/// Constants
///
private extension ItemList {
    enum Constants {
        static let bannerTitleFont: POSFontStyle = .posBodyEmphasized
        static let bannerSubtitleFont: POSFontStyle = .posDetailRegular
        static let bannerCornerRadius: CGFloat = 8
        static let bannerVerticalPadding: CGFloat = 26
        static let bannerTextSpacing: CGFloat = 4
        static let bannerTitleSpacing: CGFloat = 8
        static let infoIconPadding: CGFloat = 16
        static let bannerInfoIconSize: CGFloat = 44
        static let iconPadding: CGFloat = 26
        static let itemListPadding: CGFloat = 16
        static let bannerCardPadding: CGFloat = 16
        static let viewHeight: CGFloat = UIScreen.main.bounds.height
        static let scrollThresholdMultiplier: CGFloat = 1.7
    }

    enum BannerState {
        static let isSimpleProductsOnlyBannerDismissedKey = "isSimpleProductsOnlyBannerDismissed"
    }

    enum Localization {
        static let headerBannerTitle = NSLocalizedString(
            "pos.itemlistview.headerBanner.title",
            value: "Showing simple products only",
            comment: "Title of the product selector header banner, which explains current POS limitations"
        )

        static let headerBannerSubtitle = NSLocalizedString(
            "pos.itemlistview.headerBanner.subtitle",
            value: "Only simple physical products are available with POS right now.",
            comment: "Subtitle of the product selector header banner, which explains current POS limitations"
        )

        static let headerBannerHint = NSLocalizedString(
            "pos.itemlistview.headerBanner.hint",
            value: "Other product types, such as variable and virtual, will become available in future updates.",
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
#Preview {
    ItemListView()
}
#endif

struct ItemList: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.floatingControlAreaSize) var floatingControlAreaSize: CGSize
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var posModel: PointOfSaleAggregateModel

    @State private var lastScrollPosition: CGFloat = 0
    @State private var showSimpleProductsModal: Bool = false

    @AppStorage(BannerState.isSimpleProductsOnlyBannerDismissedKey)
    private var isHeaderBannerDismissed: Bool = false

    var rootItem: POSItem?

    @State var state: ItemListViewState?

    let showChildren: (POSItem) -> Void

    var body: some View {
        ScrollView {
            VStack {
                if dynamicTypeSize.isAccessibilitySize, shouldShowHeaderBanner {
                    bannerCardView
                }

                switch state {
                case .loading(let items, context: let context, pageInfo: let pageInfo),
                        .loaded(let items, context: let context, pageInfo: let pageInfo):
                    headerView(context: context)
                    listRows(items)
                case .none:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, floatingControlAreaSize.height)
            .padding(.horizontal, Constants.itemListPadding)
            .background(GeometryReader { proxy in
                Color.clear
                    .onChange(of: proxy.frame(in: .global).maxY) { maxY in
                        if posModel.itemListState.isLoadingAfterInitialLoad {
                            return
                        }
                        let threshold = Constants.viewHeight * Constants.scrollThresholdMultiplier
                        if maxY < threshold && maxY < lastScrollPosition {
                            Task {
                                await posModel.loadNextItems()
                            }
                        }
                        lastScrollPosition = maxY
                    }
            })
            .posModal(isPresented: $showSimpleProductsModal) {
                SimpleProductsOnlyInformation(isPresented: $showSimpleProductsModal)
            }
            .task {
                guard let rootItem else {
                    state = posModel.rootState
                    return
                }
                guard case .parentProduct(let parentProduct) = rootItem else { return }
                state = await posModel.childState(for: parentProduct)
            }
        }
    }

    @ViewBuilder
    func listRows(_ items: [POSItem]) -> some View {
                ForEach(items) { item in
                    listRow(item: item)
                }
                GhostItemCardView()
                    .renderedIf(state?.isLoading ?? false)

    }

    @ViewBuilder
    func listRow(item: POSItem) -> some View {
        switch item {
        case .product(let product):
            Button(action: {
                posModel.addToCart(product)
            }, label: {
                ProductCardView(product: product)
            })
        case .parentProduct(let parentProduct):
            Button(action: {
                withAnimation {
                    showChildren(item)
                }
            }, label: {
                ParentProductCardView(parentProduct: parentProduct)
            })
        case .variation(let variation):
            Button(action: {
                posModel.addToCart(variation)
            }, label: {
                VariationCardView(variation: variation)
            })
        }
    }
}
