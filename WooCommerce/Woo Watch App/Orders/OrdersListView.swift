import SwiftUI

/// Entry point for the order list view
///
struct OrdersListView: View {

    // Used to changed the tab programmatically
    @Binding var watchTab: WooWatchTab

    init(watchTab: Binding<WooWatchTab>) {
        self._watchTab = watchTab
    }

    var body: some View {
        VStack {
            Text("Order List...")
            Button("Go back to my store view") {
                self.watchTab = .myStore
            }
        }
    }
}
