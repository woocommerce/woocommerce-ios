import Foundation

/// Native-screen navigation the assistant delegates to the app target.
/// Keeping it as a protocol means the module never imports the main app -
/// tests stub it, previews mock it.
public protocol AssistantExternalNavigationProviding: Sendable {
    func openOrder(siteID: Int64, orderID: Int64)
    func openProduct(siteID: Int64, productID: Int64)
    func openCustomer(siteID: Int64, customerID: Int64)
}
