import SwiftUI

@available(iOS 17.0, *)
struct PointOfSaleOrdersListView: View {
    @Binding var selectedOrderID: String?
    let onClose: () -> Void

    private let orders = [
        Order(id: "order1", title: "Order 1"),
        Order(id: "order2", title: "Order 2")
    ]

    var body: some View {
        VStack(spacing: 0) {
            POSPageHeaderView(
                title: "Orders",
                backButtonConfiguration: .init(state: .enabled, action: onClose, buttonIcon: "xmark")
            )

            List(orders, id: \.id, selection: $selectedOrderID) { order in
                NavigationLink(value: order.id) {
                    Text(order.title)
                        .padding(.vertical, 8)
                }
            }
            .listStyle(.plain)
        }
        .background(Color.posSurfaceBright)
        .navigationBarHidden(true)
    }
}

private struct Order {
    let id: String
    let title: String
}

#if DEBUG
@available(iOS 17.0, *)
#Preview("List") {
    NavigationSplitView {
        PointOfSaleOrdersListView(selectedOrderID: .constant("order1"), onClose: {})
    } detail: {
        Text("Detail View")
    }
}
#endif
