public protocol AssistantExternalNavigationProviding: Sendable {
    @MainActor func openOrder(orderID: Int64)
    @MainActor func openOrder(orderID: Int64, payload: AnyCodableJSON)
    @MainActor func openProduct(productID: Int64)
    @MainActor func openProduct(productID: Int64, payload: AnyCodableJSON)
    @MainActor func openProductVariation(productID: Int64, variationID: Int64)
    @MainActor func openProductVariation(productID: Int64, variationID: Int64, payload: AnyCodableJSON)
    @MainActor func openCustomer(customerID: Int64)
    @MainActor func openCustomer(customerID: Int64, payload: AnyCodableJSON)
    @MainActor func openAnalyticsHub(payload: AnyCodableJSON)
}

public extension AssistantExternalNavigationProviding {
    @MainActor func openOrder(orderID: Int64, payload: AnyCodableJSON) { openOrder(orderID: orderID) }
    @MainActor func openProduct(productID: Int64, payload: AnyCodableJSON) { openProduct(productID: productID) }
    @MainActor func openProductVariation(productID: Int64, variationID: Int64, payload: AnyCodableJSON) {
        openProductVariation(productID: productID, variationID: variationID)
    }
    @MainActor func openCustomer(customerID: Int64, payload: AnyCodableJSON) { openCustomer(customerID: customerID) }
    @MainActor func openAnalyticsHub(payload: AnyCodableJSON) {}
}
