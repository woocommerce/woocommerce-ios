import SwiftUI

/// A scroll view that supports infinite scrolling by triggering a load more action when the user scrolls near the bottom
struct InfiniteScrollView<Content: View, LoadingView: View>: View {
    @State private var scrollViewHeight: CGFloat = 0

    private let triggerDeterminer: InfiniteScrollTriggerDeterminable
    private let loadMore: () async throws -> Void
    private let content: Content
    private let loadingView: LoadingView?

    /// - Parameters:
    ///   - triggerDeterminer: Determines when to trigger the infinite scroll load more action.
    ///   - loadMore: Async closure that loads more content when triggered.
    ///   - content: The main content view to display in the scroll view.
    ///   - loadingView: Optional loading indicator view shown at the bottom while loading more content.
    init(
        triggerDeterminer: InfiniteScrollTriggerDeterminable,
        loadMore: @escaping () async throws -> Void,
        @ViewBuilder content: () -> Content,
        @ViewBuilder loadingView: () -> LoadingView?
    ) {
        self.triggerDeterminer = triggerDeterminer
        self.loadMore = loadMore
        self.content = content()
        self.loadingView = loadingView()
    }

    var body: some View {
        ScrollView {
            content
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .onChange(of: proxy.frame(in: .named(Constants.scrollViewNamespace)).maxY) { maxY in
                                let contentHeight = proxy.size.height
                                let scrollPosition = contentHeight - maxY

                                if triggerDeterminer
                                    .shouldTriggerInfiniteScroll(
                                        scrollPosition: scrollPosition,
                                        scrollViewHeight: scrollViewHeight,
                                        contentHeight: contentHeight
                                    ) {
                                    Task { @MainActor in
                                        do {
                                            try await loadMore()
                                        } catch {
                                            triggerDeterminer.resetStatesIfNeeded()
                                        }
                                    }
                                }
                            }
                    })
            if let loadingView {
                loadingView
            }
        }
        .measureHeight { height in
            scrollViewHeight = height
        }
        .coordinateSpace(name: Constants.scrollViewNamespace)
    }
}

private enum Constants {
    static let scrollViewNamespace: String = "scrollView"
}

#if DEBUG

#Preview {
    PreviewWrapper()
}

private struct PreviewWrapper: View {
    struct Item {
        let name: String
    }

    @State private var pageNumber: Int = 1
    @State private var isLoading: Bool = false
    @State private var items: [Item] = [Int](1...20).map { Item(name: "Item \($0)") }

    var body: some View {
        InfiniteScrollView(
            triggerDeterminer: ThresholdInfiniteScrollTriggerDeterminer(),
            loadMore: {
                isLoading = true
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                pageNumber += 1
                guard items.count < 100 else { return }
                items.append(contentsOf: [Int](1...10).map { Item(name: "Page \(pageNumber) Item \($0)") })
                isLoading = false
            },
            content: {
                ForEach(items, id: \.name) { item in
                    HStack {
                        Text(item.name)
                            .font(.title)
                        Spacer()
                    }
                    .padding()
                }
            },
            loadingView: {
                ProgressView()
                    .renderedIf(isLoading)
            })
        .frame(height: 400)
    }
}

#endif
