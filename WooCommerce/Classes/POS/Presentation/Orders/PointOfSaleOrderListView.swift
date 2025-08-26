import SwiftUI
import struct Yosemite.POSOrder

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

    var body: some View {
        HStack(alignment: .center, spacing: POSSpacing.medium) {
            VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
                Text("#\(order.number)")
                    .font(.posBodySmallBold)
                    .foregroundStyle(Color.posOnSurface)

                Text(DateFormatter.dateAndTimeFormatter.string(from: order.dateCreated))
                    .font(.posBodySmallRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)

                if let customerEmail = order.customerEmail {
                    Text(customerEmail)
                        .font(.posBodySmallRegular())
                        .foregroundStyle(Color.posOnSurfaceVariantHighest)
                }
            }
            .multilineTextAlignment(.leading)

            Spacer()

            VStack(alignment: .trailing, spacing: POSSpacing.xSmall) {
                Text("\(order.currencySymbol)\(order.total)")
                    .font(.posBodyLargeBold)
                    .foregroundStyle(Color.posOnSurface)

                HStack(spacing: POSSpacing.xSmall) {
                    Image(systemName: "creditcard.fill")
                        .foregroundStyle(Color.posSuccess)
                        .font(.caption)
                    Text("Completed")
                        .font(.posBodySmallRegular())
                        .foregroundStyle(Color.posSuccess)
                }
            }
            .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, POSPadding.medium)
        .padding(.vertical, POSPadding.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? Color.posSurfaceDim : Color.posSurfaceContainerLowest)
        .posItemCardBorderStyles()
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
