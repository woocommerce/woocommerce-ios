import SwiftUI
import UIKit
import struct WooFoundation.WooAnalyticsEvent
import struct Yosemite.POSOrder

struct POSOrdersView: View {
    @Binding var isPresented: Bool
    @Environment(POSOrderListModel.self) private var orderListModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.posAnalytics) private var analytics
    @State private var isSearching: Bool = false
    @State private var searchTerm: String = ""
    @State private var activeRefundSelectionOrderID: Int64?
    @State private var pendingOrderSelection: POSOrder?
    @State private var isCancelRefundConfirmationPresented = false

    var body: some View {
        contentView
            .task {
                await orderListModel.ordersController.loadOrders()
            }
    }

    @ViewBuilder
    private var contentView: some View {
        switch (orderListModel.ordersController.ordersViewState, isSearching) {
        case (.error(let error), false):
            errorView(error)
        case (.empty, false):
            emptyView()
        default:
            POSNavigationSplitView(selection: Binding(
                get: { orderListModel.ordersController.selectedOrder },
                set: { selectOrder($0) }
            )) { _ in
                POSOrderListView(
                    isSearching: $isSearching,
                    searchTerm: $searchTerm,
                    onOrderSelected: { handleOrderSelection($0) }
                ) {
                    isPresented = false
                }
                .environment(orderListModel)
            } detail: { selection, detailNavigationPath in
                POSOrderDetailsView(
                    order: selection,
                    detailNavigationPath: detailNavigationPath,
                    activeRefundSelectionOrderID: $activeRefundSelectionOrderID,
                    onBack: {
                        selectOrder(nil)
                    }
                )
                .id(selection.id)
                .environment(orderListModel)
            } detailPlaceholderView: {
                if orderListModel.ordersController.ordersViewState.isLoading {
                    POSOrderDetailsLoadingView()
                } else {
                    POSOrderDetailsEmptyView()
                }
            } setDefaultValue: {
                if orderListModel.ordersController.selectedOrder == nil,
                   let firstOrder = orderListModel.ordersController.ordersViewState.orders.first {
                    selectOrder(firstOrder)
                }
            }
            .onChange(of: orderListModel.ordersController.ordersViewState.orders) { oldOrders, newOrders in
                guard horizontalSizeClass == .regular else { return }

                guard let firstOrder = newOrders.first else {
                    selectOrder(nil)
                    return
                }

                if let selectedOrder = orderListModel.ordersController.selectedOrder, newOrders.map(\.id).contains(selectedOrder.id) {
                    return
                }

                selectOrder(firstOrder)
            }
            .animation(.default, value: orderListModel.ordersController.ordersViewState.orders.isEmpty)
            .onAppear {
                analytics.track(event: WooAnalyticsEvent.PointOfSale.ordersListLoaded())
            }
            .onDisappear {
                activeRefundSelectionOrderID = nil
                selectOrder(nil)
            }
            .alert(Localization.cancelRefundAlertTitle,
                   isPresented: $isCancelRefundConfirmationPresented,
                   presenting: pendingOrderSelection) { order in
                Button(Localization.keepEditingRefundButton, role: .cancel) {
                    pendingOrderSelection = nil
                }
                Button(Localization.cancelRefundButton, role: .destructive) {
                    cancelActiveRefundSelectionAndSelect(order)
                }
            } message: { _ in
                Text(Localization.cancelRefundAlertMessage)
            }
        }
    }

    @ViewBuilder
    private func errorView(_ error: PointOfSaleErrorState) -> some View {
        ZStack {
            VStack {
                Spacer()
                POSListErrorView(error: error) {
                    Task { @MainActor in
                        await orderListModel.ordersController.loadOrders()
                    }
                }
                Spacer()
            }

            VStack {
                POSPageHeaderView(
                    title: POSOrderListView.Localization.ordersTitle,
                    backButtonConfiguration: .init(state: .enabled, action: {
                        isPresented = false
                    }))
                .posHeaderBackButtonIcon(systemName: "xmark")
                Spacer()
            }
        }
    }

    @ViewBuilder
    private func emptyView() -> some View {
        ZStack {
            VStack {
                Spacer()
                POSListEmptyView(
                    viewModel: POSOrderListEmptyViewModel(isSearching: false)
                ) {
                    Task { @MainActor in
                        await orderListModel.ordersController.loadOrders()
                    }
                }
                Spacer()
            }

            VStack {
                POSPageHeaderView(
                    title: POSOrderListView.Localization.ordersTitle,
                    backButtonConfiguration: .init(state: .enabled, action: {
                        isPresented = false
                    }))
                .posHeaderBackButtonIcon(systemName: "xmark")
                Spacer()
            }
        }
    }
}

private extension POSOrdersView {
    func handleOrderSelection(_ order: POSOrder) {
        guard orderListModel.ordersController.selectedOrder?.id != order.id else {
            return
        }

        guard activeRefundSelectionOrderID != nil else {
            selectOrder(order)
            return
        }

        if orderListModel.ordersController.hasModifiedRefundSelection {
            pendingOrderSelection = order
            isCancelRefundConfirmationPresented = true
        } else {
            cancelActiveRefundSelectionAndSelect(order)
        }
    }

    func cancelActiveRefundSelectionAndSelect(_ order: POSOrder) {
        activeRefundSelectionOrderID = nil
        pendingOrderSelection = nil
        orderListModel.ordersController.clearRefundSelection()
        selectOrder(order)
    }

    func selectOrder(_ order: POSOrder?) {
        if orderListModel.ordersController.selectedOrder?.id != order?.id {
            activeRefundSelectionOrderID = nil
            pendingOrderSelection = nil
        }
        orderListModel.ordersController.selectOrder(order)
    }
}

private enum Localization {
    static let cancelRefundAlertTitle = NSLocalizedString(
        "pos.ordersView.cancelRefundAlert.title",
        value: "Cancel this refund?",
        comment: "Title for an alert asking whether to cancel an in-progress POS refund before selecting another order."
    )

    static let cancelRefundAlertMessage = NSLocalizedString(
        "pos.ordersView.cancelRefundAlert.message",
        value: "Your current refund selection will be discarded.",
        comment: "Message for an alert asking whether to cancel an in-progress POS refund before selecting another order."
    )

    static let keepEditingRefundButton = NSLocalizedString(
        "pos.ordersView.cancelRefundAlert.keepEditing.button",
        value: "Keep editing",
        comment: "Button to keep editing the current POS refund selection instead of selecting another order."
    )

    static let cancelRefundButton = NSLocalizedString(
        "pos.ordersView.cancelRefundAlert.cancelRefund.button",
        value: "Cancel refund",
        comment: "Button to cancel the current POS refund selection and select another order."
    )
}

#if DEBUG
#Preview("Orders View List") {
    POSOrdersView(isPresented: .constant(true))
        .environment(POSPreviewHelpers.makePreviewOrdersModel(state: POSPreviewHelpers.loadedState()))
}

#Preview("Orders View Empty") {
    POSOrdersView(isPresented: .constant(true))
        .environment(POSPreviewHelpers.makePreviewOrdersModel(state: .empty))
}

#Preview("Orders View Error") {
    POSOrdersView(isPresented: .constant(true))
        .environment(POSPreviewHelpers.makePreviewOrdersModel(state: .error(.errorOnLoadingOrders())))
}
#endif
