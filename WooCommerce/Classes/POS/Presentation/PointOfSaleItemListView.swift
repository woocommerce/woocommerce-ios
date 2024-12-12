import SwiftUI
import Yosemite

/// Displays a list of items in POS. Can be a list of parent/product items, or child items.
/// It supports pull-to-refresh and infinite scrolling.
struct PointOfSaleItemListView<Content>: View where Content: View {
    @Environment(\.floatingControlAreaSize) var floatingControlAreaSize: CGSize
    @Binding var itemListState: ItemListState

    @State private var lastScrollPosition: CGFloat = 0
    @State private var showSimpleProductsModal: Bool = false

    let reload: () async -> Void
    let loadNextItems: () async -> Void

    @ViewBuilder var itemContent: (POSDisplayableItem) -> Content

    var body: some View {
        VStack {
            switch itemListState {
                case .initialLoading:
                    // These cases are handled directly in the dashboard, we do not render
                    // a specific view within the ItemListView to handle them
                    // TODO: make this view generic? this is empty for top-level items, and non-empty for variation items
//                    EmptyView()
                    listView(items: [])
                        .transition(.slide)
                case .empty:
                    PointOfSaleItemListEmptyView()
                case let .error(error):
                    PointOfSaleItemListErrorView(error: error, onRetry: {
                        Task {
                            // TODO: DI loadInitialItems
                            //                            await viewModel.loadInitialItems()
                        }
                    })
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
                case .loading(let items),
                        .loaded(let items):
                    listView(items: items)
                        .transition(.slide)
            }
        }
        .refreshable {
            Task { @MainActor in
                await reload()
            }
        }
        .background(Color.posPrimaryBackground)
        .accessibilityElement(children: .contain)
        .posModal(isPresented: $showSimpleProductsModal) {
            SimpleProductsOnlyInformation(isPresented: $showSimpleProductsModal)
        }
    }

    private func listView(items: [POSDisplayableItem]) -> some View {
        ScrollView {
            VStack {
                // TODO: recover banner view
//                if dynamicTypeSize.isAccessibilitySize, shouldShowHeaderBanner {
//                    bannerCardView
//                }
                ForEach(items, id: \.id) { item in
                    itemContent(item)
                }
                GhostItemCardView()
                    .renderedIf(itemListState.isLoading)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, floatingControlAreaSize.height)
            .padding(.horizontal, Constants.itemListPadding)
            .background(GeometryReader { proxy in
                Color.clear
                    .onChange(of: proxy.frame(in: .global).maxY) { maxY in
                        if itemListState.isLoading {
                            return
                        }
                        let threshold = Constants.viewHeight * Constants.scrollThresholdMultiplier
                        if maxY < threshold && maxY < lastScrollPosition {
                            Task {
                                await loadNextItems()
                            }
                        }
                        lastScrollPosition = maxY
                    }
            })
        }
    }
}

private enum Constants {
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

//#Preview {
//    PointOfSaleItemListView()
//}
