import Foundation
import Yosemite

/// ViewModel for the `SimplePaymentsMethods` view.
///
final class SimplePaymentsMethodsViewModel: ObservableObject {

    /// Navigation bar title.
    ///
    let title: String

    /// Store's ID.
    ///
    private let siteID: Int64

    /// Order's ID to update
    ///
    private let orderID: Int64

    /// Formatted total to charge.
    ///
    private let formattedTotal: String

    /// Store manager to update order.
    ///
    private let stores: StoresManager

    init(siteID: Int64 = 0, orderID: Int64 = 0, formattedTotal: String, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.orderID = orderID
        self.formattedTotal = formattedTotal
        self.stores = stores
        self.title = Localization.title(total: formattedTotal)
    }

    /// Creates the info text when the merchant selects the cash payment method.
    ///
    func payByCashInfo() -> String {
        Localization.markAsPaidInfo(total: formattedTotal)
    }
}

private extension SimplePaymentsMethodsViewModel {
    enum Localization {
        static func title(total: String) -> String {
            NSLocalizedString("Take Payment (\(total))", comment: "Navigation bar title for the Simple Payments Methods screens")
        }

        static func markAsPaidInfo(total: String) -> String {
            NSLocalizedString("This will mark your order as complete if you received \(total) outside of WooCommerce",
                              comment: "Alert info when selecting the cash payment method for simple payments")
        }
    }
}
