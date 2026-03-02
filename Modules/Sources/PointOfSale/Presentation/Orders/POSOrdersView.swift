import SwiftUI
import UIKit
import struct WooFoundation.WooAnalyticsEvent
import struct WooFoundation.SafariView

struct POSOrdersView: View {
    @Binding var isPresented: Bool
    @Environment(POSOrderListModel.self) private var orderListModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.posAnalytics) private var analytics
    @State private var isSearching: Bool = false
    @State private var searchTerm: String = ""
    @State private var showBlog = false
    @State private var isShowingEmailReceiptView = false

    var body: some View {
        contentView
            .task {
                await orderListModel.ordersController.loadOrders()
            }
            .posFullScreenCover(isPresented: $isShowingEmailReceiptView) {
                if let order = orderListModel.ordersController.selectedOrder {
                    POSSendReceiptView(isShowingSendReceiptView: $isShowingEmailReceiptView) { email in
                        try await orderListModel.sendReceipt(order: order, email: email)
                    }
                    .posHeaderBackButtonIcon(systemName: "xmark")
                }
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
                set: { orderListModel.ordersController.selectOrder($0) }
            )) { _ in
                POSOrderListView(isSearching: $isSearching, searchTerm: $searchTerm) {
                    isPresented = false
                }
                .environment(orderListModel)
            } detail: { selection, _ in
                POSOrderDetailsView(
                    order: selection,
                    onBack: {
                        orderListModel.ordersController.selectOrder(nil)
                    },
                    isShowingEmailReceiptView: $isShowingEmailReceiptView
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
                    orderListModel.ordersController.selectOrder(firstOrder)
                }
            }
            .onChange(of: orderListModel.ordersController.ordersViewState.orders) { oldOrders, newOrders in
                guard horizontalSizeClass == .regular else { return }

                guard let firstOrder = newOrders.first else {
                    orderListModel.ordersController.selectOrder(nil)
                    return
                }

                if let selectedOrder = orderListModel.ordersController.selectedOrder, newOrders.map(\.id).contains(selectedOrder.id) {
                    return
                }

                orderListModel.ordersController.selectOrder(firstOrder)
            }
            .animation(.default, value: orderListModel.ordersController.ordersViewState.orders.isEmpty)
            .onAppear {
                analytics.track(event: WooAnalyticsEvent.PointOfSale.ordersListLoaded())
            }
            .onDisappear {
                orderListModel.ordersController.selectOrder(nil)
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
                    showBlog = true
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
        .posFullScreenCover(isPresented: $showBlog) {
            SafariView(url: POSConstants.URLs.wooCommerceBlog.asURL())
        }
    }
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
