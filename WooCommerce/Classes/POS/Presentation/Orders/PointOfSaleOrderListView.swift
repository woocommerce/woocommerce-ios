import SwiftUI
import struct Yosemite.POSOrder
import enum Yosemite.OrderPaymentMethod

struct PointOfSaleOrderListView: View {
    @Binding var selectedOrderID: String?
    let onClose: () -> Void

    @Environment(PointOfSaleOrderListModel.self) private var orderListModel
    @StateObject private var infiniteScrollTriggerDeterminer = ThresholdInfiniteScrollTriggerDeterminer()

    private var ordersViewState: OrderListState {
        orderListModel.ordersController.ordersViewState
    }

    var body: some View {
        VStack(spacing: 0) {
            POSPageHeaderView(
                title: "Orders",
                isLoading: {
                    if case .loading(let orders) = ordersViewState {
                        return !orders.isEmpty
                    }
                    return false
                }(),
                backButtonConfiguration: .init(state: .enabled, action: onClose, buttonIcon: "xmark")
            )

            InfiniteScrollView(
                triggerDeterminer: infiniteScrollTriggerDeterminer,
                loadMore: {
                    guard case .loaded(_, let hasMoreItems) = ordersViewState, hasMoreItems else { return }
                    await orderListModel.ordersController.loadNextOrders()
                },
                content: {
                    LazyVStack(spacing: 8) {
                        headerRows

                        switch ordersViewState {
                        case .empty:
                            Text("No orders")
                        case .error(let errorState):
                            ItemListErrorCardView(errorState: errorState) {
                                Task { @MainActor in
                                    await orderListModel.ordersController.loadOrders()
                                }
                            }
                        default:
                            let orders = ordersViewState.orders
                            ForEach(orders, id: \.id) { order in
                                Button(action: {
                                    selectedOrderID = String(order.id)
                                }) {
                                    OrderRowView(order: order, isSelected: selectedOrderID == String(order.id))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }

                        footerRows
                    }
                    .padding(.horizontal)
                }
            )
        }
        .background(Color.posSurfaceBright)
        .navigationBarHidden(true)
        .refreshable {
            await orderListModel.ordersController.refreshOrders()
        }
        .task {
            await orderListModel.ordersController.loadOrders()
        }
    }

    @ViewBuilder
    private var headerRows: some View {
        switch ordersViewState {
        case .inlineError(_, let errorState, .refresh):
            ItemListErrorCardView(errorState: errorState) {
                Task { @MainActor in
                    await orderListModel.ordersController.loadOrders()
                }
            }
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var footerRows: some View {
        switch ordersViewState {
        case .loading(let orders):
            if orders.isEmpty {
                ForEach(0..<8, id: \.self) { _ in
                    GhostItemCardView()
                }
            } else {
                GhostItemCardView()
            }
        case .inlineError(_, let errorState, .pagination):
            ItemListErrorCardView(errorState: errorState) {
                Task { @MainActor in
                    await orderListModel.ordersController.loadNextOrders()
                }
            }
        default:
            EmptyView()
        }
    }
}

private struct OrderRowView: View {
    let order: POSOrder
    let isSelected: Bool

    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    private var minHeight: CGFloat {
        min(Constants.orderCardMinHeight * scale, Constants.maximumOrderCardHeight)
    }

    var body: some View {
        HStack(alignment: .center, spacing: POSSpacing.medium) {
            VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
                Text("#\(order.number)")
                    .font(.posBodySmallBold)
                    .foregroundStyle(Color.posOnSurface)
                    .fixedSize(horizontal: false, vertical: true)

                Text(DateFormatter.dateAndTimeFormatter.string(from: order.dateCreated))
                    .font(.posBodySmallRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
                    .fixedSize(horizontal: false, vertical: true)


                if let customerEmail = order.customerEmail, customerEmail.isNotEmpty {
                    Text(customerEmail)
                        .font(.posBodySmallRegular())
                        .foregroundStyle(Color.posOnSurfaceVariantHighest)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .multilineTextAlignment(.leading)

            Spacer()

            VStack(alignment: .trailing, spacing: POSSpacing.xSmall) {
                Text("\(order.currencySymbol)\(order.total)")
                    .font(.posBodyLargeBold)
                    .foregroundStyle(Color.posOnSurface)

                HStack(spacing: POSSpacing.xSmall) {
                    if let paymentMethodIcon = paymentMethodIcon {
                        Image(systemName: paymentMethodIcon)
                            .foregroundStyle(statusColor)
                            .font(.caption)
                    }
                    Text(order.status.localizedName)
                        .font(.posBodySmallRegular())
                        .foregroundStyle(statusColor)
                }
            }
            .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, POSPadding.medium * (1 / scale))
        .padding(.vertical, POSPadding.medium * (1 / scale))
        .frame(maxWidth: .infinity, minHeight: dynamicTypeSize.isAccessibilitySize ? nil : minHeight, alignment: .leading)
        .background(isSelected ? Color.posSurfaceDim : Color.posSurfaceContainerLowest)
        .posItemCardBorderStyles()
    }

    private enum Constants {
        static let orderCardMinHeight: CGFloat = 90
        static let maximumOrderCardHeight: CGFloat = Constants.orderCardMinHeight * 2
    }
}

private extension OrderRowView {
    var paymentMethodIcon: String? {
        let paymentMethod = OrderPaymentMethod(rawValue: order.paymentMethodID)
        switch paymentMethod {
        case .cod:
            return "banknote"
        case .stripe, .woocommercePayments:
            return "creditcard"
        default:
            return nil
        }
    }

    var statusColor: Color {
        switch order.status {
        case .completed:
            return .posSuccess
        case .failed:
            return .posError
        default:
            return .posOnSurfaceVariantLowest
        }
    }
}

#if DEBUG
#Preview("List") {
    NavigationSplitView {
        PointOfSaleOrdersListView(selectedOrderID: .constant("1"), onClose: {})
            .navigationSplitViewColumnWidth(450)
            .environment(POSPreviewHelpers.makePreviewOrdersModel())
    } detail: {
        Text("Detail View")
    }
}
#endif
