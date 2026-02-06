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
            CustomNavigationSplitView(selection: Binding(
                get: { orderListModel.ordersController.selectedOrder },
                set: { orderListModel.ordersController.selectOrder($0) }
            )) { _ in
                POSOrderListView(isSearching: $isSearching, searchTerm: $searchTerm) {
                    isPresented = false
                }
                .environment(orderListModel)
            } detail: { selection in
                POSOrderDetailsView(
                    order: selection,
                    onBack: {
                        orderListModel.ordersController.selectOrder(nil)
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
