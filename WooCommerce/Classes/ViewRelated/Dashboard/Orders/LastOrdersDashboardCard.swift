import SwiftUI
import struct Yosemite.DashboardCard
import struct Yosemite.Order

/// View for displaying orders on the dashboard.
///
struct LastOrdersDashboardCard: View {
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
        VStack(alignment: .leading, spacing: Layout.padding) {
            header
                .padding(.horizontal, Layout.padding)

            filterBar
                .padding(.horizontal, Layout.padding)
                .redacted(reason: viewModel.syncingData ? [.placeholder] : [])
                .shimmering(active: viewModel.syncingData)

            Divider()

            if let _ = viewModel.syncingError {
                DashboardCardErrorView(onRetry: {
                    ServiceLocator.analytics.track(event: .DynamicDashboard.cardRetryTapped(type: .lastOrders))
                    Task {
                        await viewModel.reloadData()
                    }
                })
                .padding(.horizontal, Layout.padding)
            } else {
                if viewModel.syncingData || viewModel.rows.isNotEmpty {
                    orderList
                } else {
                    emptyView
                }

                viewAllOrdersButton
                    .padding(.horizontal, Layout.padding)
                    .redacted(reason: viewModel.syncingData ? [.placeholder] : [])
                    .shimmering(active: viewModel.syncingData)
            }

        }
        .padding(.vertical, Layout.padding)
        .background(Color(.listForeground(modal: false)))
        .clipShape(RoundedRectangle(cornerSize: Layout.cornerSize))
        .padding(.horizontal, Layout.padding)
    }
}

private extension LastOrdersDashboardCard {
    var emptyView: some View {
        VStack(spacing: 0) {
            LastOrdersDashboardEmptyView(orderStatus: viewModel.selectedOrderStatus)
                .frame(maxWidth: .infinity)

            Divider()
                .padding(.leading, Layout.padding)
        }
    }

    var viewAllOrdersButton: some View {
        Button {
            ServiceLocator.analytics.track(event: .DynamicDashboard.dashboardCardInteracted(type: .lastOrders))

            onViewAllOrders()
        } label: {
            HStack {
                Text(Localization.viewAll)
                Spacer()
                Image(systemName: "chevron.forward")
                    .foregroundStyle(Color(.tertiaryLabel))
            }
        }
        .disabled(viewModel.syncingData)
    }

    var header: some View {
        HStack {
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(Color.secondary)
                .headlineStyle()
                .renderedIf(viewModel.syncingError != nil)
            Text(DashboardCard.CardType.lastOrders.name)
                .headlineStyle()
            Spacer()
            Menu {
                Button(Localization.hideCard) {
                    viewModel.dismiss()
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(Color.secondary)
                    .padding(.leading, Layout.padding)
                    .padding(.vertical, Layout.hideIconVerticalPadding)
            }
            .disabled(viewModel.syncingData)
        }
    }

    var filterBar: some View {
        HStack {
            Text(Localization.status)
                .foregroundStyle(Color.primary)
                .subheadlineStyle()
            Text(viewModel.status)
                .subheadlineStyle()
            Spacer()
            Menu {
                ForEach(viewModel.allStatuses) { status in
                    Button {
                        ServiceLocator.analytics.track(event: .DynamicDashboard.dashboardCardInteracted(type: .lastOrders))

                        Task { @MainActor in
                            await viewModel.updateOrderStatus(status)
                        }
                    } label: {
                        SelectableItemRow(title: status.description, selected: status.status == viewModel.selectedOrderStatus)
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
                    .foregroundStyle(Color(.secondaryLabel))
            }

        }
    }

    var orderList: some View {
        VStack(alignment: .leading, spacing: Layout.padding) {
            ForEach(viewModel.rows) { element in
                LastOrderDashboardRow(viewModel: element, tapHandler: {
                    ServiceLocator.analytics.track(event: .DynamicDashboard.dashboardCardInteracted(type: .lastOrders))

                    onViewOrderDetail(element.order)
                })
            }
            .redacted(reason: viewModel.syncingData ? [.placeholder] : [])
            .shimmering(active: viewModel.syncingData)
        }
    }
}

private extension LastOrdersDashboardCard {
    enum Layout {
        static let padding: CGFloat = 16
        static let cornerSize = CGSize(width: 8.0, height: 8.0)
        static let hideIconVerticalPadding: CGFloat = 8
    }

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
    LastOrdersDashboardCard(viewModel: .init(siteID: 123),
                            onViewAllOrders: { },
                            onViewOrderDetail: { _ in })
}
