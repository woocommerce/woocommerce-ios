import SwiftUI

struct PointOfSaleOrderDetailsView: View {
    let orderID: String
    let onBack: () -> Void
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var orderTitle: String {
        switch orderID {
        case "order1":
            return "Order 1"
        case "order2":
            return "Order 2"
        default:
            return "Unknown Order"
        }
    }

    // Show back button when in compact mode (phone) where the detail view
    // is presented as a pushed view, not when in regular mode (tablet split view)
    private var shouldShowBackButton: Bool {
        horizontalSizeClass == .compact
    }

    var body: some View {
        VStack(spacing: 0) {
            POSPageHeaderView(
                title: orderTitle,
                backButtonConfiguration: shouldShowBackButton ?
                    .init(state: .enabled, action: onBack) : nil
            )

            VStack(alignment: .leading, spacing: 20) {
                Text("Order details will be displayed here")
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .background(Color.posSurface)
        .navigationBarHidden(true)
    }
}

#if DEBUG
#Preview("Details - Order 1") {
    NavigationStack {
        PointOfSaleOrderDetailsView(orderID: "order1", onBack: {})
    }
}

#Preview("Details - Order 2") {
    NavigationStack {
        PointOfSaleOrderDetailsView(orderID: "order2", onBack: {})
    }
}
#endif
