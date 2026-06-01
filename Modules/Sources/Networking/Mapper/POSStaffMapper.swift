import Foundation

/// Maps the `GET /wc/pos/v1/staff` JSON response into `[POSStaffMember]`.
///
/// Handles both shapes the iOS networking layer can produce:
/// - Direct REST: `{"staff": [...]}` (e.g. application-password requests)
/// - Jetpack tunnel: `{"data": {"staff": [...]}}` (the WPCOM `data` envelope wrapper that
///   `/rest/v1.1/jetpack-blogs/<id>/rest-api/?path=...` adds around the underlying WC response).
///
/// On envelope decode failure, retries as a `WordPressApiError` so WC REST error bodies
/// (e.g. `woocommerce_rest_cannot_view` on 401) surface as a typed error the adaptor can
/// branch on, rather than as a generic `DecodingError`.
///
struct POSStaffMapper: Mapper {
    func map(response: Data) throws -> [POSStaffMember] {
        let decoder = JSONDecoder()
        do {
            if hasDataEnvelope(in: response) {
                return try decoder.decode(POSStaffDataEnvelope.self, from: response).data.staff
            }
            return try decoder.decode(POSStaffEnvelope.self, from: response).staff
        } catch {
            if let wpError = try? decoder.decode(WordPressApiError.self, from: response) {
                throw wpError
            }
            throw error
        }
    }
}

private struct POSStaffDataEnvelope: Decodable {
    let data: POSStaffEnvelope
}

private struct POSStaffEnvelope: Decodable {
    let staff: [POSStaffMember]
}
