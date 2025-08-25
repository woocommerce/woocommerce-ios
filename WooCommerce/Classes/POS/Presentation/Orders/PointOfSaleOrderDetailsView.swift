import SwiftUI
import struct Yosemite.POSOrder
import struct Yosemite.POSOrderItem
import struct Yosemite.POSOrderRefund

struct PointOfSaleOrderDetailsView: View {
    let orderID: String?
    let onBack: () -> Void

    @Environment(PointOfSaleOrdersModel.self) private var ordersModel

    private var order: POSOrder? {
        guard let orderID = orderID,
              let orderIDInt = Int64(orderID) else { return nil }
        return ordersModel.ordersController.ordersViewState.orders.first { $0.id == orderIDInt }
    }

    // Show back button when in compact mode (phone) where the detail view
    // is presented as a pushed view, not when in regular mode (tablet split view)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var shouldShowBackButton: Bool {
        horizontalSizeClass == .compact
    }

    var body: some View {
        VStack(spacing: 0) {
            POSPageHeaderView(
                title: order.map { "Order #\($0.number)" } ?? "Order Details",
                backButtonConfiguration: shouldShowBackButton ? .init(state: .enabled, action: onBack) : nil
            )

            if let order = order {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        orderSummarySection(order)
                        productsSection(order)
                        totalsSection(order)
                    }
                    .padding()
                }
            } else {
                VStack {
                    Spacer()
                    Text("Order not found")
                    Spacer()
                }
            }
        }
        .background(Color.posSurface)
        .navigationBarHidden(true)
    }



    @ViewBuilder
    private func orderSummarySection(_ order: POSOrder) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Order #\(order.number)")
                    .font(.headline)
                Spacer()
                Text(order.status.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Date & Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(order.dateCreated, style: .date)
                    Text(order.dateCreated, style: .time)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(order.currencySymbol)\(order.total)")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            }

            if let customerEmail = order.customerEmail {
                HStack {
                    Text("Customer Email")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(customerEmail)
                }
            }

            HStack {
                Text("Payment Method")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(order.paymentMethodTitle)
            }
        }
        .padding()
        .background(Color.posSurface)
        .cornerRadius(12)
    }

    @ViewBuilder
    private func productsSection(_ order: POSOrder) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Products")
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(order.lineItems, id: \.itemID) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name)
                                .fontWeight(.medium)
                            Text("Qty: \(item.quantity.intValue)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("\(order.currencySymbol)\(item.total)")
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .background(Color.posSurface)
                    .cornerRadius(8)
                }
            }
        }
    }

    @ViewBuilder
    private func totalsSection(_ order: POSOrder) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Totals")
                .font(.headline)

            VStack(spacing: 8) {
                HStack {
                    Text("Subtotal")
                    Spacer()
                    Text("\(order.currencySymbol)\(order.total)")
                }

                Divider()

                HStack {
                    Text("Total")
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(order.currencySymbol)\(order.total)")
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Paid")
                    Spacer()
                    Text("\(order.currencySymbol)\(order.total)")
                }

                if !order.refunds.isEmpty {
                    let refundedTotal = order.refunds.reduce(0.0) { $0 + (Double($1.total) ?? 0.0) }
                    HStack {
                        Text("Refunded")
                        Spacer()
                        Text("-\(order.currencySymbol)\(String(format: "%.2f", refundedTotal))")
                            .foregroundColor(.red)
                    }

                    let netPayment = (Double(order.total) ?? 0.0) - refundedTotal
                    HStack {
                        Text("Net Payment")
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(order.currencySymbol)\(String(format: "%.2f", netPayment))")
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding()
            .background(Color.posSurface)
            .cornerRadius(8)
        }
    }

}


#if DEBUG
#Preview("Order Details") {
    PointOfSaleOrderDetailsView(orderID: "1", onBack: {})
        .environment(POSPreviewHelpers.makePreviewOrdersModel())
}
#endif
