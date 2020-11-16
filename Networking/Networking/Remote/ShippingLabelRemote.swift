import Foundation

/// Shipping Labels Remote Endpoints.
public final class ShippingLabelRemote: Remote {
    /// Generates shipping label data for printing.
    /// - Parameters:
    ///   - siteID: Remote ID of the site that owns the shipping label.
    ///   - shippingLabelID: Remote ID of the shipping label.
    ///   - paperSize: Paper size string (current options are "label", "legal", and "letter").
    ///   - completion: Closure to be executed upon completion.
    public func printShippingLabel(siteID: Int64,
                                   shippingLabelID: Int64,
                                   paperSize: String,
                                   completion: @escaping (Result<ShippingLabelPrintData, Error>) -> Void) {
        let parameters = [
            ParameterKey.paperSize: paperSize,
            ParameterKey.labelIDCSV: String(shippingLabelID),
            ParameterKey.cationCSV: "",
            ParameterKey.json: "true" // `json=true` is necessary, otherwise it results in 500 error "no_response_body".
        ]
        let path = "\(Path.shippingLabels)/print"
        let request = JetpackRequest(wooApiVersion: .wcConnectV1, method: .get, siteID: siteID, path: path, parameters: parameters)
        let mapper = ShippingLabelPrintDataMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }
}

// MARK: Constant
private extension ShippingLabelRemote {
    enum Path {
        static let shippingLabels = "label"
    }

    enum ParameterKey {
        static let paperSize = "paper_size"
        static let labelIDCSV = "label_id_csv"
        static let cationCSV = "caption_csv"
        static let json = "json"
    }
}
