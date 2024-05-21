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
        NavigationSplitView() {
            List() {
                Section {
                    OrderListCard()
                    OrderListCard()
                    OrderListCard()
                    OrderListCard()
                    OrderListCard()
                    OrderListCard()
                    OrderListCard()
                    OrderListCard()
                }
            }
            .navigationTitle("Orders")
            .listStyle(.plain)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        self.watchTab = .myStore
                    } label: {
                        Label("", systemImage: "house")
                    }
                }
            }
        } detail: {
            Text("Order Detail")
        }
    }
}

struct OrderListCard: View {
    var body: some View {
        VStack(alignment: .leading) {

            HStack {
                Text("25 Feb")
                Spacer()
                Text("#1031")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            Text("Jemima Kirk")
                .font(.body)

            Text("$149.50")
                .font(.body)
                .bold()

            Text("Pending payment")
                .font(.footnote)
                .foregroundStyle(Colors.wooPurple20)
        }
        .listRowBackground(
            LinearGradient(gradient: Gradient(colors: [Colors.wooBackgroundStart, Colors.wooBackgroundEnd]), startPoint: .top, endPoint: .bottom)
                .cornerRadius(10)
        )
    }
}

private extension OrderListCard {
    enum Colors {
        static let wooPurple20 = Color(red: 190/255.0, green: 160/255.0, blue: 242/255.0)
        static let wooBackgroundStart = Color(red: 69/255.0, green: 43/255.0, blue: 100/255.0)
        static let wooBackgroundEnd = Color(red: 49/255.0, green: 31/255.0, blue: 71/255.0)
    }
}
