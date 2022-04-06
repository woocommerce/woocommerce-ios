import UITestsFoundation
import XCTest

/// Helpers for actions that flow across different New Order screens.
///
class NewOrderFlow {

    /// Changes the new order status to the second status in the Order Status list.
    /// - Returns: New Order screen object.
    @discardableResult
    static func editOrderStatus() throws -> NewOrderScreen {
        return try NewOrderScreen().openOrderStatusScreen()
            .selectOrderStatus(atIndex: 1)
            .confirmSelectedOrderStatus()
    }
}
