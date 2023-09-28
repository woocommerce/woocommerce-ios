import Foundation

/// Mapper: `CouponReport`
///
struct CouponReportListMapper: Mapper {

    /// (Attempts) to convert a dictionary into `[CouponReport]`.
    ///
    func map(response: Data) throws -> [CouponReport] {
        let decoder = JSONDecoder()
        if hasDataEnvelope(in: response) {
            return try decoder.decode(Envelope<[CouponReport]>.self, from: response).data
        } else {
            return try decoder.decode([CouponReport].self, from: response)
        }
    }
}
