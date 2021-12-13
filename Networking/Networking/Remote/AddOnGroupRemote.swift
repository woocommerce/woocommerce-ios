import Foundation

/// `AddOnGroup` remote endpoints.
///
public final class AddOnGroupRemote: Remote {

    /// Retrieves all the `AddOnGroups` available for a given `siteID`
    ///
    public func loadAddOnGroups(siteID: Int64, onCompletion: @escaping (Result<[AddOnGroup], Error>) -> ()) {
        let request = JetpackRequest(wooApiVersion: .addOnsV1, method: .get, siteID: siteID, path: Path.addOnGroups)
        let mapper = AddOnGroupMapper(siteID: siteID)
        enqueue(request, mapper: mapper, completion: onCompletion)
    }
}

// MARK: - Constants
//
private extension AddOnGroupRemote {
    private enum Path {
        static let addOnGroups = "product-add-ons"
    }
}
