import SwiftUI

/// Contains an activity indicator (spinner) in the center when `showContent` is `true`.
/// Used at the bottom of a list view that supports infinite scroll.
struct InfiniteScrollIndicator: View {
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
