import SwiftUI
import UIKit

struct POSOrdersView: View {
    @Binding var isPresented: Bool
    @Environment(POSOrderListModel.self) private var orderListModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.posAnalytics) private var analytics

    var body: some View {
        switch orderListModel.ordersController.ordersViewState {
        case .error(let error):
            errorView(error)
        default:
            CustomNavigationSplitView(selection: Binding(
                get: { orderListModel.ordersController.selectedOrder },
                set: { orderListModel.ordersController.selectOrder($0) }
            )) { _ in
                POSOrderListView() {
                    isPresented = false
                }
            } detail: { selection in
                POSOrderDetailsView(
                    order: selection,
                    onBack: {
                        orderListModel.ordersController.selectOrder(nil)
                    }
                )
                .id(selection.id)
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
        VStack(spacing: 0) {
            POSPageHeaderView(
                title: POSOrderListView.Localization.ordersTitle,
                backButtonConfiguration: .init(state: .enabled, action: {
                    isPresented = false
                }))
            .posHeaderBackButtonIcon(systemName: "xmark")

            POSListErrorView(error: error) {
                Task { @MainActor in
                    await orderListModel.ordersController.loadOrders()
                }
            }
        }
    }
}

// MARK: - Split View
/// An alternative split view implementation that gives more control of the split view design, including the sidebar and content arrangement and separator colors
/// Just as NavigationSplitView, it adapts to a list -> details navigation on smaller screens
/// It may be used as a common component in the future
///
private struct CustomNavigationSplitView<Sidebar: View, Detail: View, DetailPlaceholder: View, SelectionValue: Hashable>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding private var selection: SelectionValue?

    private let sidebar: (Binding<SelectionValue?>) -> Sidebar
    private let detail: (SelectionValue) -> Detail
    private let detailPlaceholderView: () -> DetailPlaceholder
    private let setDefaultValue: (() -> Void)?

    init(
        selection: Binding<SelectionValue?> = .constant(nil),
        @ViewBuilder sidebar: @escaping (Binding<SelectionValue?>) -> Sidebar,
        @ViewBuilder detail: @escaping (SelectionValue) -> Detail,
        @ViewBuilder detailPlaceholderView: @escaping () -> DetailPlaceholder,
        setDefaultValue: (() -> Void)? = nil
    ) {
        self._selection = selection
        self.sidebar = sidebar
        self.detail = detail
        self.detailPlaceholderView = detailPlaceholderView
        self.setDefaultValue = setDefaultValue
    }

    var body: some View {
        switch horizontalSizeClass {
        case .regular:
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    sidebar($selection)
                        .frame(width: geometry.size.width * Constants.sidebarWidthFraction)

                    VStack {
                        if let selection = selection {
                            detail(selection)
                                .frame(maxWidth: .infinity)
                                .transition(.opacity)
                        } else {
                            detailPlaceholderView()
                                .frame(maxWidth: .infinity)
                                .transition(.opacity)
                        }
                    }
                    .animation(.default, value: selection != nil)
                }
            }
            .onAppear {
                if selection == nil {
                    setDefaultValue?()
                }
            }
        default:
            NavigationStack {
                sidebar($selection)
                    .navigationDestination(isPresented: Binding(
                        get: { selection != nil },
                        set: { if !$0 { selection = nil } }
                    )) {
                        if let selection = selection {
                            detail(selection)
                        }
                    }
            }
        }
    }
}

private enum Constants {
    static let sidebarWidthFraction: CGFloat = 0.35
}

#if DEBUG
#Preview("Orders View") {
    POSOrdersView(isPresented: .constant(true))
        .environment(POSPreviewHelpers.makePreviewOrdersModel(state: .empty))
}
#endif
