import SwiftUI
import UIKit

struct PointOfSaleOrdersView: View {
    @Binding var isPresented: Bool
    @Environment(PointOfSaleOrderListModel.self) private var orderListModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        CustomNavigationSplitView(selection: Binding(
            get: { orderListModel.ordersController.selectedOrder },
            set: { orderListModel.ordersController.selectOrder($0) }
        )) { _ in
            PointOfSaleOrderListView() {
                isPresented = false
            }
        } detail: { selection in
            PointOfSaleOrderDetailsView(
                onBack: {
                    orderListModel.ordersController.selectOrder(nil)
                }
            )
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
    }
}

// MARK: - Split View
/// An alternative split view implementation that gives more control of the split view design, including the sidebar and content arrangement and separator colors
/// Just as NavigationSplitView, it adapts to a list -> details navigation on smaller screens
/// It may be used as a common component in the future
///
private struct CustomNavigationSplitView<Sidebar: View, Detail: View, SelectionValue: Hashable>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding private var selection: SelectionValue?

    private let sidebar: (Binding<SelectionValue?>) -> Sidebar
    private let detail: (SelectionValue) -> Detail
    private let setDefaultValue: (() -> Void)?

    init(
        selection: Binding<SelectionValue?> = .constant(nil),
        @ViewBuilder sidebar: @escaping (Binding<SelectionValue?>) -> Sidebar,
        @ViewBuilder detail: @escaping (SelectionValue) -> Detail,
        setDefaultValue: (() -> Void)? = nil
    ) {
        self._selection = selection
        self.sidebar = sidebar
        self.detail = detail
        self.setDefaultValue = setDefaultValue
    }

    var body: some View {
        switch horizontalSizeClass {
        case .regular:
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    sidebar($selection)
                        .frame(width: geometry.size.width * Constants.sidebarWidthFraction)

                    if let selection = selection {
                        detail(selection)
                            .frame(maxWidth: .infinity)
                    } else {
                        EmptyView()
                    }
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
    PointOfSaleOrdersView(isPresented: .constant(true))
        .environment(POSPreviewHelpers.makePreviewOrdersModel())
}
#endif
