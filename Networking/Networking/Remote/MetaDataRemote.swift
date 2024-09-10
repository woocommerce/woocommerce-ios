import Foundation

/// Interface for remote requests to Product and Orders meta data.
///
public protocol MetaDataRemoteProtocol {
    func updateMetaData(for siteID: Int64, for parentID: Int64, type: MetaDataType, metadata: [[String: String]]) async throws -> [MetaData]
}

public final class MetaDataRemote: Remote, MetaDataRemoteProtocol {

    // MARK: - MetaData

    /// Updates metadata for a specific item.
    ///
    /// - Parameters:
    ///     - site: Site for which we'll update the metadata.
    ///     - request: The request containing metadata to be updated.
    ///     - type: The type of item (order or product) for which we'll update the metadata.
    /// - Returns: An array of updated MetaData.
    ///
    public func updateMetaData(for siteID: Int64, for parentID: Int64, type: MetaDataType, metadata: [[String: String]]) async throws -> [MetaData] {

        let parameters: [String: Any] = [ParameterKey.metaData: metadata, ParameterKey.fields: "meta_data"]
        let path: String
        switch type {
        case .order:
            path = "\(Path.orders)/\(parentID)"
        case .product:
            path = "\(Path.products)/\(parentID)"
        }
        let request = JetpackRequest(wooApiVersion: .mark3, method: .post, siteID: siteID, path: path, parameters: parameters, availableAsRESTRequest: true)
        let mapper = MetaDataMapper()

        return try await enqueue(request, mapper: mapper)

    }
}

// MARK: - Constants

private extension MetaDataRemote {
    enum Path {
        static let orders = "orders"
        static let products = "products"
    }

    enum ParameterKey {
        static let fields = "_fields"
        static let metaData = "meta_data"
    }
}

public enum MetaDataType {
    case order
    case product
}
