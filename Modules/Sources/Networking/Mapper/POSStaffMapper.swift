import Foundation

/// Maps the `GET /wc-pos/v1/staff` JSON response into `[POSStaffMember]`.
///
/// On envelope decode failure, retries as a `WordPressApiError` so WC REST error bodies
/// (e.g. `woocommerce_rest_cannot_view` on 401) surface as a typed error the adaptor can
/// branch on, rather than as a generic `DecodingError`.
///
struct POSStaffMapper: Mapper {
    func map(response: Data) throws -> [POSStaffMember] {
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(POSStaffEnvelope.self, from: response).staff
        } catch let envelopeError {
            if let wpError = try? decoder.decode(WordPressApiError.self, from: response) {
                throw wpError
            }
            throw envelopeError
        }
    }
}

private struct POSStaffEnvelope: Decodable {
    let staff: [POSStaffMember]
}
