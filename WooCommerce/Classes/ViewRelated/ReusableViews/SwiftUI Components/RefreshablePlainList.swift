import SwiftUI

/// A refreshable ScrollView wrapper.
///
struct RefreshablePlainList<Content: View>: View {
    let action: () async -> Void
    let content: Content

    init(action: @escaping () async -> Void, content: @escaping () -> Content) {
        self.action = action
        self.content = content()
    }

    var body: some View {
        ScrollView {
            content
        }
        .refreshable {
            await action()
        }
    }
}
