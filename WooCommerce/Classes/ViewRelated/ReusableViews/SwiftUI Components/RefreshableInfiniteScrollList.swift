import SwiftUI

/// A refreshable list that renders the provided list content with an infinite scroll indicator with pull-to-refresh support.
struct RefreshableInfiniteScrollList<Content: View>: View {
    /// Content to render in the list.
    ///
    private let listContent: Content

    /// Whether the list is loading more content. Used to determine whether to show the infinite scroll indicator.
    ///
    private let isLoading: Bool

    /// Action to load more content.
    ///
    private let loadAction: () -> Void

    /// Action to refresh content.
    ///
    private let refreshAction: RefreshableScrollView<Content>.RefreshAction

    /// Creates a list with the provided content and an infinite scroll indicator.
    ///
    /// - Parameters:
    ///   - isLoading: Whether the list is loading more content. Used to determine whether to show the infinite scroll indicator.
    ///   - loadAction: Action to load more content.
    ///   - refreshAction: Called when the user pulls-to-refresh content in the scroll list.
    ///   - listContent: Content to render in the list.
    init(isLoading: Bool,
         loadAction: @escaping () -> Void,
         refreshAction: @escaping RefreshableScrollView<Content>.RefreshAction,
         @ViewBuilder listContent: () -> Content) {
        self.listContent = listContent()
        self.isLoading = isLoading
        self.loadAction = loadAction
        self.refreshAction = refreshAction
    }

    var body: some View {
        RefreshableScrollView(refreshAction: refreshAction) {
            LazyVStack(spacing: 0) {
                listContent

                InfiniteScrollIndicator(showContent: isLoading)
                    .onAppear {
                        loadAction()
                    }
            }
        }
    }
}

struct RefreshableInfiniteScrollList_Previews: PreviewProvider {
    static var previews: some View {
        RefreshableInfiniteScrollList(isLoading: true, loadAction: {}, refreshAction: { isComplete in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isComplete()
            }
        }) {
            ForEach((0..<6)) { index in
                Text("Item \(index)")
            }
        }
        .previewDisplayName("Refreshable infinite scroll list: Loading")
        .previewLayout(.sizeThatFits)

        RefreshableInfiniteScrollList(isLoading: false, loadAction: {}, refreshAction: { isComplete in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isComplete()
            }
        }) {
            ForEach((0..<6)) { index in
                Text("Item \(index)")
            }
        }
        .previewDisplayName("Refreshable infinite scroll list: Loaded")
        .previewLayout(.sizeThatFits)
    }
}
