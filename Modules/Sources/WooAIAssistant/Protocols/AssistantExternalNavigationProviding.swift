@MainActor
public protocol AssistantExternalNavigationProviding {
    func openOrder(orderID: Int64)
    func openOrder(orderID: Int64, payload: AnyCodableJSON)
    func openProduct(productID: Int64)
    func openProduct(productID: Int64, payload: AnyCodableJSON)
    func openProductVariation(productID: Int64, variationID: Int64)
    func openProductVariation(productID: Int64, variationID: Int64, payload: AnyCodableJSON)
    func openCustomer(customerID: Int64)
    func openCustomer(customerID: Int64, payload: AnyCodableJSON)
    func openAnalyticsHub(payload: AnyCodableJSON)
}

public extension AssistantExternalNavigationProviding {
    func openOrder(orderID: Int64, payload: AnyCodableJSON) { openOrder(orderID: orderID) }
    func openProduct(productID: Int64, payload: AnyCodableJSON) { openProduct(productID: productID) }
    func openProductVariation(productID: Int64, variationID: Int64, payload: AnyCodableJSON) {
        openProductVariation(productID: productID, variationID: variationID)
    }
    func openCustomer(customerID: Int64, payload: AnyCodableJSON) { openCustomer(customerID: customerID) }
    func openAnalyticsHub(payload: AnyCodableJSON) {}
}
