import StoreDesignSystem
import SwiftUI
import struct Yosemite.DashboardCard
import struct Yosemite.Order

/// View for displaying orders on the dashboard.
///
struct StoreLastOrdersDashboardCard: View {
    @ObservedObject private var viewModel: LastOrdersDashboardCardViewModel
    private let onViewAllOrders: () -> Void
    private let onViewOrderDetail: (_ order: Order) -> Void

    init(viewModel: LastOrdersDashboardCardViewModel,
         onViewAllOrders: @escaping () -> Void,
         onViewOrderDetail: @escaping (_ order: Order) -> Void) {
        self.viewModel = viewModel
        self.onViewAllOrders = onViewAllOrders
        self.onViewOrderDetail = onViewOrderDetail
    }

    var body: some View {
        StoreDashboardCardSurface {
            VStack(alignment: .leading, spacing: StoreSpacing.s0) {
                header

                if viewModel.syncingError != nil {
                    errorState
                } else {
                    filterBar
                        .redacted(reason: viewModel.syncingData ? [.placeholder] : [])
                        .shimmering(active: viewModel.syncingData)
                    StoreDivider()

                    if viewModel.syncingData || viewModel.rows.isNotEmpty {
                        orderList
                    } else {
                        StoreLastOrdersDashboardEmptyView(statusName: viewModel.selectedOrderStatusDisplayName)
                    }

                    StoreDashboardCardFooterAction(Localization.viewAll,
                                                   isDisabled: viewModel.syncingData,
                                                   action: viewAllOrders)
                        .redacted(reason: viewModel.syncingData ? [.placeholder] : [])
                        .shimmering(active: viewModel.syncingData)
                }
            }
        }
    }
}

private extension StoreLastOrdersDashboardCard {
    func viewAllOrders() {
        ServiceLocator.analytics.track(event: .DynamicDashboard.dashboardCardInteracted(type: .lastOrders))
        onViewAllOrders()
    }

    var header: some View {
        StoreDashboardCardHeader(DashboardCard.CardType.lastOrders.name,
                                 showsError: viewModel.syncingError != nil) {
            StoreDashboardCardOverflowMenu(isDisabled: viewModel.syncingData) {
                Button(Localization.hideCard, action: viewModel.dismiss)
            }
        }
    }

    var filterBar: some View {
        StoreDashboardCardFilterHeader(
            title: Localization.status,
            selectedOptionTitle: viewModel.status,
            options: viewModel.allStatuses,
            isDisabled: viewModel.syncingData,
            optionTitle: viewModel.title,
            isSelected: { $0.status == viewModel.selectedOrderStatus },
            onSelect: selectStatus
        )
    }

    var orderList: some View {
        VStack(alignment: .leading, spacing: StoreSpacing.s0) {
            ForEach(viewModel.rows) { element in
                StoreLastOrderDashboardRow(data: element.rowData, tapHandler: {
                    ServiceLocator.analytics.track(event: .DynamicDashboard.dashboardCardInteracted(type: .lastOrders))
                    onViewOrderDetail(element.order)
                })
            }
            .redacted(reason: viewModel.syncingData ? [.placeholder] : [])
            .shimmering(active: viewModel.syncingData)
        }
    }

    var errorState: some View {
        StoreDashboardCardErrorView {
            ServiceLocator.analytics.track(event: .DynamicDashboard.cardRetryTapped(type: .lastOrders))
            Task { await viewModel.reloadData() }
        }
    }

    func selectStatus(_ status: LastOrdersDashboardCardViewModel.OrderStatusRow) {
        ServiceLocator.analytics.track(event: .DynamicDashboard.dashboardCardInteracted(type: .lastOrders))
        Task { @MainActor in
            await viewModel.updateOrderStatus(status)
        }
    }
}

private extension StoreLastOrdersDashboardCard {
    enum Localization {
        static let hideCard = NSLocalizedString(
            "lastOrdersDashboardCard.hideCard",
            value: "Hide Orders",
            comment: "Menu item to dismiss the Last Orders section on the My Store screen"
        )
        static let status = NSLocalizedString(
            "lastOrdersDashboardCard.status",
            value: "Status",
            comment: "Header label on the Last Orders section on the My Store screen"
        )
        static let viewAll = NSLocalizedString(
            "lastOrdersDashboardCard.viewAll",
            value: "View all orders",
            comment: "Button to navigate to Orders list screen."
        )
    }
}

#Preview {
    StoreLastOrdersDashboardCard(viewModel: .init(siteID: 123),
                            onViewAllOrders: { },
                            onViewOrderDetail: { _ in })
}
