import SwiftUI

struct POSNavigationRouter {
    @Binding var navigationPath: [POSNavigationDestination]

    var isNavigated: Bool { !navigationPath.isEmpty }

    func pushCash(orderTotal: String) {
        guard navigationPath.isEmpty else { return }
        navigationPath.append(.cashPayment(orderTotal: orderTotal))
    }

    func pushEmailReceipt() {
        navigationPath.append(.emailReceipt)
    }

    func pop() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast()
    }

    func popToRoot() {
        navigationPath.removeAll()
    }
}

// MARK: - View Modifiers

private struct OnNewOrderClearNavigationModifier: ViewModifier {
    let orderStage: PointOfSaleOrderStage
    @Binding var navigationPath: [POSNavigationDestination]

    func body(content: Content) -> some View {
        content
            .onChange(of: orderStage) { _, newValue in
                guard newValue == .building, !navigationPath.isEmpty else { return }
                navigationPath.removeAll()
            }
    }
}

extension View {
    func onNewOrderClearNavigation(orderStage: PointOfSaleOrderStage,
                                   navigationPath: Binding<[POSNavigationDestination]>) -> some View {
        modifier(OnNewOrderClearNavigationModifier(orderStage: orderStage, navigationPath: navigationPath))
    }
}
