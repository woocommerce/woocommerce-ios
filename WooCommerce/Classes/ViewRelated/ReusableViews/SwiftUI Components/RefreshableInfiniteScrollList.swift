import SwiftUI

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

private struct InfiniteScrollIndicator: View {

    let showContent: Bool

    var body: some View {
        if #available(iOS 15.0, *) {
            createProgressView()
                .listRowSeparator(.hidden, edges: .bottom)
        } else {
            createProgressView()
        }
    }

    @ViewBuilder func createProgressView() -> some View {
        ProgressView()
            .frame(maxWidth: .infinity, alignment: .center)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color(.listBackground))
            .if(!showContent) { progressView in
                progressView.hidden() // Hidden but still in view hierarchy so `onAppear` will trigger the load action when needed
            }
    }
}

struct RefreshableInfiniteScrollList_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
//        RefreshableInfiniteScrollList<<#Content: View#>>()
    }
}
