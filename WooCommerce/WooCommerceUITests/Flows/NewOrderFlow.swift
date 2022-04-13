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


    /// Select the first product from the addProductScreen
    /// - Returns: New Order screen object.
    @discardableResult
    static func addProduct() throws -> NewOrderScreen {
        let products = try GetMocks.readProductsData()  // if we need use this in other functions in this flow, it'll have to be a private function
        return try NewOrderScreen().openAddProductScreen()
            .selectProduct(byName: products[0].name)
    }
}
