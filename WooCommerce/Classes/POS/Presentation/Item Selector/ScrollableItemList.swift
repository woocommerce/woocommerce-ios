import SwiftUI

/// Scrollable list of items in POS, with an optional given view above the item list.
struct ScrollableItemList<HeaderView: View>: View {
    private let state: ItemListState
    private let headerView: HeaderView

    @Environment(\.floatingControlAreaSize) private var floatingControlAreaSize: CGSize

    init(
        state: ItemListState,
        @ViewBuilder headerView: () -> HeaderView
    ) {
        self.state = state
        self.headerView = headerView()

    }

    var body: some View {
        ScrollView {
            VStack {
                ItemList(state: state)
                    .background(Color.posPrimaryBackground)
                    .toolbar(.hidden, for: .navigationBar)
                    .transition(.opacity)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, floatingControlAreaSize.height)
            .padding(.horizontal, Constants.itemListPadding)
        }
    }
}

private enum Constants {
    static let itemListPadding: CGFloat = 16
}

#Preview {
    ScrollableItemList(state: .loading([]), headerView: { EmptyView() })
}
