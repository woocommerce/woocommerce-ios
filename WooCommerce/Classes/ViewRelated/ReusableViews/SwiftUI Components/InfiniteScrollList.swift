import SwiftUI

/// A list that renders the provided list content with an infinite scroll indicator.
///
struct InfiniteScrollList<Content: View>: View {
    /// Content to render in the list.
    ///
    private let listContent: Content

    /// Whether the list is loading more content. Used to determine whether to show the infinite scroll indicator.
    ///
    private let isLoading: Bool

    /// Action to load more content.
    ///
    private let loadAction: () -> Void

    /// Creates a list with the provided content and an infinite scroll indicator.
    ///
    /// - Parameters:
    ///   - isLoading: Whether the list is loading more content. Used to determine whether to show the infinite scroll indicator.
    ///   - loadAction: Action to load more content.
    ///   - listContent: Content to render in the list.
    init(isLoading: Bool,
         loadAction: @escaping () -> Void,
         @ViewBuilder listContent: () -> Content) {
        self.listContent = listContent()
        self.isLoading = isLoading
        self.loadAction = loadAction
    }

    var body: some View {
        List {
            listContent

            InfiniteScrollIndicator(showContent: isLoading)
                .onAppear {
                    loadAction()
                }
        }
        .listStyle(PlainListStyle())
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

struct InfiniteScrollList_Previews: PreviewProvider {
    static var previews: some View {
        InfiniteScrollList(isLoading: true, loadAction: {}) {
            ForEach((0..<6)) { index in
                Text("Item \(index)")
            }
        }
        .previewDisplayName("Infinite scroll list: Loading")
        .previewLayout(.sizeThatFits)

        InfiniteScrollList(isLoading: false, loadAction: {}) {
            ForEach((0..<6)) { index in
                Text("Item \(index)")
            }
        }
        .previewDisplayName("Infinite scroll list: Loaded")
        .previewLayout(.sizeThatFits)
    }
}
