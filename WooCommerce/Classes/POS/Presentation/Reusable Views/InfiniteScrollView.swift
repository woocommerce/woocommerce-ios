import SwiftUI

protocol InfiniteScrollTriggerDeterminable {
    func shouldTriggerInfiniteScroll(scrollPosition: CGFloat, scrollViewHeight: CGFloat, contentHeight: CGFloat) -> Bool
    func resetStatesIfNeeded()
}

final class InfiniteScrollTriggerDeterminer: InfiniteScrollTriggerDeterminable, ObservableObject {
    private var lastTriggeredContentHeight: CGFloat?

    func shouldTriggerInfiniteScroll(scrollPosition: CGFloat, scrollViewHeight: CGFloat, contentHeight: CGFloat) -> Bool {
        let scrollableHeight = contentHeight - scrollViewHeight
        let scrollPercentage = scrollPosition * 1.0 / scrollableHeight

        // If content is shorter than scroll view, do not trigger infinite scroll from scrolling.
        // Instead, the next page should be loaded from the initial load if the content height does not fill the scroll view.
        guard contentHeight > scrollViewHeight else {
            return false
        }

        // Only triggers if we haven't triggered at this content height before.
        if scrollPercentage >= Constants.scrollTriggerThreshold &&
            lastTriggeredContentHeight != contentHeight {
            lastTriggeredContentHeight = contentHeight
            return true
        } else {
            return false
        }
    }

    func resetStatesIfNeeded() {
        lastTriggeredContentHeight = nil
    }

    private enum Constants {
        static let scrollTriggerThreshold: CGFloat = 0.7
    }
}

struct InfiniteScrollView<Content: View, LoadingView: View>: View {
    @State private var lastScrollPosition: CGFloat = 0
    @State private var scrollViewHeight: CGFloat = 0

    private let triggerDeterminer: InfiniteScrollTriggerDeterminable
    private let loadMore: () async throws -> Void
    private let content: Content
    private let loadingView: LoadingView?

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
                    Color.clear.onChange(of: proxy.frame(in: .named(Constants.scrollViewNamespace)).maxY) { maxY in
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
        .background(
            GeometryReader { scrollViewProxy in
                Color.clear
                    .onAppear {
                        scrollViewHeight = scrollViewProxy.size.height
                    }
                    .onChange(of: scrollViewProxy.size.height) { newHeight in
                        scrollViewHeight = newHeight
                    }
            }
        )
        .coordinateSpace(name: Constants.scrollViewNamespace)
        .onAppear {

        }
    }
}

private enum Constants {
    static let scrollViewNamespace: String = "scrollView"
}

//#Preview {
//    RefreshableInfiniteScrollView(shouldLoadMore: .constant(false)) {
//        // Replace with your actual content view
//        Text("Content View")
//    }
//}
