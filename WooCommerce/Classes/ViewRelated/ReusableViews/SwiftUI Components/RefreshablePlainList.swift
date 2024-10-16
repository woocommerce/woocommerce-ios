import SwiftUI

/// This view simulates pull-to-refresh support on ScrollView before iOS 16.
///
/// On iOS 16+ it uses ScrollView.
/// On iOS 15 it falls back to List with modifiers removing all its default rows styling.
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
