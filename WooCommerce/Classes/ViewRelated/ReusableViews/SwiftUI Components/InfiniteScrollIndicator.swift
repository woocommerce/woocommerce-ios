import SwiftUI

/// Contains an activity indicator (spinner) in the center when `showContent` is `true`.
/// Used at the bottom of a list view that supports infinite scroll.
struct InfiniteScrollIndicator: View {
    let showContent: Bool

    var body: some View {
        createProgressView()
            .listRowSeparator(.hidden, edges: .bottom)
    }

    @ViewBuilder func createProgressView() -> some View {
        ProgressView()
            .opacity(showContent ? 1 : 0)
            .frame(maxWidth: .infinity, alignment: .center)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color(.listBackground))
            .accessibilityElement()
            .accessibilityLabel(Localization.accessibilityLabel)
    }
}

private extension InfiniteScrollIndicator {
    enum Localization {
        static let accessibilityLabel = NSLocalizedString("Loading", comment: "Accessibility label for loading indicator (spinner) at the bottom of a list")
    }
}

struct InfiniteScrollIndicator_Previews: PreviewProvider {
    static var previews: some View {
        InfiniteScrollIndicator(showContent: true)
            .previewDisplayName("Showing content")
            .previewLayout(.sizeThatFits)

        InfiniteScrollIndicator(showContent: false)
            .previewDisplayName("Hiding content")
            .previewLayout(.sizeThatFits)
    }
}
