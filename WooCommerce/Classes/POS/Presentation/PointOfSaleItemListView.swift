import SwiftUI
import enum Yosemite.POSItem

/// Displays a list of items in POS. Can be a list of parent/product items, or child items.
/// It supports pull-to-refresh and infinite scrolling.
struct PointOfSaleItemListView<Content>: View where Content: View {
    @Binding var itemListState: ItemListState

    @State private var lastScrollPosition: CGFloat = 0
    @State private var showSimpleProductsModal: Bool = false

    @ViewBuilder var itemContent: (POSItem) -> Content

    var body: some View {
        VStack {
            switch itemListState {
            case .initialLoading, .empty, .error:
                // These cases are handled directly in the dashboard, we do not render
                // a specific view within the ItemListView to handle them
                EmptyView()
            case .loading(let items, _, _),
                    .loaded(let items, _, _):
                listView(items: items).transition(.slide)
            }
        }
        .refreshable {
            // TODO: DI reload
//            await posModel.reload()
        }
        .background(Color.posPrimaryBackground)
        .accessibilityElement(children: .contain)
        .posModal(isPresented: $showSimpleProductsModal) {
            SimpleProductsOnlyInformation(isPresented: $showSimpleProductsModal)
        }
    }

    private func listView(items: [POSItem]) -> some View {
        ScrollView {
            VStack {
//                if dynamicTypeSize.isAccessibilitySize, shouldShowHeaderBanner {
//                    bannerCardView
//                }
                ForEach(items) { item in
                    itemContent(item)
                }
                GhostItemCardView()
                    .renderedIf(itemListState.isLoadingAfterInitialLoad)
            }
            .frame(maxWidth: .infinity)
//            .padding(.bottom, floatingControlAreaSize.height)
//            .padding(.horizontal, Constants.itemListPadding)
//            .background(GeometryReader { proxy in
//                Color.clear
//                    .onChange(of: proxy.frame(in: .global).maxY) { maxY in
//                        if posModel.itemListState.isLoadingAfterInitialLoad {
//                            return
//                        }
//                        let threshold = Constants.viewHeight * Constants.scrollThresholdMultiplier
//                        if maxY < threshold && maxY < lastScrollPosition {
//                            Task {
//                                await posModel.loadNextItems()
//                            }
//                        }
//                        lastScrollPosition = maxY
//                    }
//            })
        }
    }
}

//#Preview {
//    PointOfSaleItemListView()
//}
