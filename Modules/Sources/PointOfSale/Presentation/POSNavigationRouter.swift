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

// MARK: - Navigation Destination Wrappers

/// Thin wrapper that resolves environment dependencies for the cash payment NavigationStack destination.
struct POSNavigationDestinationCashPaymentView: View {
    let orderTotal: String
    @Environment(\.posCurrencyProvider) private var currencyProvider

    var body: some View {
        PointOfSaleCollectCashView(orderTotal: orderTotal,
                                   currencySettings: currencyProvider.currencySettings)
        .navigationBarHidden(true)
    }
}

/// Thin wrapper that resolves environment dependencies for the email receipt NavigationStack destination.
struct POSNavigationDestinationEmailReceiptView: View {
    @Environment(POSPaymentModel.self) private var paymentModel
    @Environment(\.posNavigationRouter) private var router

    var body: some View {
        POSSendReceiptView(onDismiss: {
            router.pop()
        }) { email in
            try await paymentModel.sendReceipt(to: email)
        }
        .navigationBarHidden(true)
    }
}
