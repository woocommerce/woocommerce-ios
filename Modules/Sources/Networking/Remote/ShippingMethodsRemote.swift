import Foundation

/// ShippingMethodsRemote: Remote Endpoints
///
public final class ShippingMethodsRemote: Remote {

    /// Retrieves all of the shipping methods for a given store.
    /// - Parameter siteID: Site for which we'll fetch the shipping methods.
    /// - Returns: A list of shipping methods.
    public func loadShippingMethods(for siteID: Int64) async throws -> [ShippingMethod] {
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: Constants.path,
                                     parameters: nil,
                                     availableAsRESTRequest: true)
        let mapper = ShippingMethodListMapper(siteID: siteID)

        return try await  enqueue(request, mapper: mapper)
    }
}


// MARK: - Constants
//
private extension ShippingMethodsRemote {

    enum Constants {
        static let path: String    = "shipping_methods"
    }
}
