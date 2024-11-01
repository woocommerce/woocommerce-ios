import SwiftUI
import protocol Yosemite.POSItem

struct ItemListView: View {
    @Environment(\.floatingControlAreaSize) private var floatingControlAreaSize: CGSize
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @Binding var itemListContainerState: ItemListContainerViewState

    @State private var isHeaderBannerDismissed: Bool = UserDefaults.standard.bool(forKey: BannerState.isSimpleProductsOnlyBannerDismissedKey)
    @State private var showSimpleProductsModal: Bool = false

    @State private var itemListState: PointOfSaleItemListState = .initializing
    let itemsService: POSItemsService
    @State private var allItems: [any POSDisplayableItem] = []
    private var currentPage: Int = Constants.initialPage

    init(itemListContainerState: Binding<ItemListContainerViewState>,
         itemsService: POSItemsService) {
        self._itemListContainerState = itemListContainerState
        self.itemsService = itemsService
    }

    var body: some View {
        VStack {
            headerView
                .posModal(isPresented: $showSimpleProductsModal) {
                    SimpleProductsOnlyInformation(isPresented: $showSimpleProductsModal)
                }
            switch itemListState {
            case .initializing, .initialLoading, .empty, .error:
                // These cases are shown in the dashboard, we do not render
                // a specific view within the ItemListView to handle them, we just set bindings
                EmptyView()
            case .loading(let items), .loaded(let items):
                listView(items)
            }
        }
        .task {
            await loadInitialItems()
        }
        .onChange(of: itemListState, perform: { newValue in
            switch newValue {
            case .initialLoading:
                itemListContainerState = .initialLoading
            case .empty:
                itemListContainerState = .empty
            case .error(let errorState):
                itemListContainerState = .error(errorState, reloadItems)
            case .initializing, .loaded, .loading:
                itemListContainerState = .show
            }
        })
        .refreshable {
            await reloadItems()
        }
        .background(Color.posPrimaryBackground)
        .accessibilityElement(children: .contain)
    }
}

/// View Helpers
///
private extension ItemListView {
    @ViewBuilder
    var headerView: some View {
        VStack {
            HStack {
                POSHeaderTitleView()
                if isHeaderBannerDismissed {
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
            if !dynamicTypeSize.isAccessibilitySize, !isHeaderBannerDismissed {
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
                    UserDefaults.standard.set(isHeaderBannerDismissed, forKey: BannerState.isSimpleProductsOnlyBannerDismissedKey)
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

    @ViewBuilder
    func listView(_ items: [any POSDisplayableItem]) -> some View {
        ScrollView {
            VStack {
                if dynamicTypeSize.isAccessibilitySize, !isHeaderBannerDismissed {
                    bannerCardView
                }
                ForEach(items, id: \.id) { item in
                    AnyView(item)
                }
            }
            .padding(.bottom, floatingControlAreaSize.height)
            .padding(.horizontal, Constants.itemListPadding)
            .background(GeometryReader { proxy in
                Color.clear
                    .onChange(of: proxy.frame(in: .global).maxY) { maxY in
                        if case .loading = itemListState {
                            return
                        }
                        let viewHeight = UIScreen.main.bounds.height
                        if maxY < viewHeight {
                            Task {
                                await loadNextItems()
                            }
                        }
                    }
            })
        }
    }
}

private extension ItemListView {
    @MainActor
    func loadInitialItems() async {
        do {
            itemListState = .initialLoading
            try await fetchItems(pageNumber: 1)
        } catch {
            itemListState = .error(PointOfSaleErrorState.errorOnLoadingProducts())
        }
    }

    @MainActor
    func loadNextItems() async {
        // TODO: Optimize API calls. gh-14186
        // If there are no more pages to fetch, we can avoid the next call.
        let nextPage = currentPage + 1
        await loadItems(pageNumber: nextPage)
    }

    @MainActor
    func loadItems(pageNumber: Int) async {
        do {
            itemListState = .loading(allItems)
            try await fetchItems(pageNumber: pageNumber)
        } catch {
            itemListState = .error(PointOfSaleErrorState.errorOnLoadingProducts())
        }
    }

    @MainActor
    func fetchItems(pageNumber: Int) async throws {
        let newItems = try await itemsService.fetchItems(pageNumber: pageNumber)
        let uniqueNewItems = newItems
            .filter { newItem in
                !allItems.contains(where: { $0.id == newItem.itemID })
            }
            .compactMap(createPOSDisplayableItem(for:))

        allItems.append(contentsOf: uniqueNewItems)

        if allItems.count == 0 {
            itemListState = .empty
        } else {
            itemListState = .loaded(allItems)
        }
    }

    @MainActor
    func reloadItems() async {
        removeAllItems()
        await loadItems(pageNumber: 1)
    }

    func removeAllItems() {
        allItems.removeAll()
    }
}

/// Constants
///
private extension ItemListView {
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

        static let initialPage: Int = 1
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


extension ItemListView {
    struct BannerState {
        static let isSimpleProductsOnlyBannerDismissedKey = "isSimpleProductsOnlyBannerDismissed"
    }
}

#if DEBUG
import class WooFoundation.MockAnalyticsPreview
#Preview {
    ItemListView(itemListContainerState: .constant(.show),
                 itemsService: POSItemsService(itemProvider: POSItemProviderPreview()))
}
#endif
