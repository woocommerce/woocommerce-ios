import Foundation

enum POSNavigationDestination: Hashable {
    case cashPayment(orderTotal: String)
    case emailReceipt
}
