import Foundation

enum POSNavigationDestination: Hashable {
    case cashPayment(orderTotal: String)
    case scanToPay(orderTotal: String)
    case markAsPaid(orderTotal: String)
    case emailReceipt
}
