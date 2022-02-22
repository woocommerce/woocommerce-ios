import SwiftUI

/// A scroll view with pull-to-refresh support.
struct RefreshableScrollView<Content: View>: View {
    /// Callback that is triggered once refreshing completes.
    typealias RefreshComplete = () -> Void

    /// Refresh action that is called once refreshing starts.
    /// `RefreshComplete` callback is triggered when refreshing completes.
    typealias RefreshAction = (@escaping RefreshComplete) -> Void

    /// Used to determine whether the spinner is shown or hidden.
    @State private var isRefreshing: Bool = false

    /// Keeps track of whether refresh action is enabled: it is enabled when the refresh action is not in progress.
    /// Since `isRefreshing` boolean is set with animation when the spinner is shown/hidden, a separate boolean is needed.
    @State private var canRefresh: Bool = true

    private let refreshAction: RefreshAction
    private let content: Content

    // MARK: Constants

    private let minOffsetToRefresh: CGFloat = 50.0

    init(refreshAction: @escaping RefreshAction,
         @ViewBuilder content: () -> Content) {
        self.refreshAction = refreshAction
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    if isRefreshing {
                        ProgressView()
                            .padding()
                    }
                    content
                        .anchorPreference(key: OffsetPreferenceKey.self, value: .top) {
                            geometry[$0].y
                        }
                }
            }
            .onPreferenceChange(OffsetPreferenceKey.self) { offset in
                DispatchQueue.main.async {
                    guard isRefreshing == false else {
                        return
                    }
                    if canRefresh {
                        if offset > minOffsetToRefresh {
                            withAnimation {
                                isRefreshing = true
                                canRefresh = false
                                refreshAction {
                                    isRefreshing = false
                                }
                            }
                        }
                    } else {
                        // As the spinner animates back to hidden state, the scroll view is back to be refreshable once offset is back to 0.
                        if offset <= 0 {
                            canRefresh = true
                        }
                    }
                }
            }
            .animation(.easeInOut, value: isRefreshing)
        }
    }
}

private struct OffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#if DEBUG

struct RefreshableScrollView_Previews: PreviewProvider {
    static var previews: some View {
        RefreshableScrollView(refreshAction: { isComplete in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isComplete()
            }
        }) {
            Text("refreshable view")
        }
    }
}

#endif
