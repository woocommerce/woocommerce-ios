import Foundation

/// Mapper: `BlazePaymentInfo`
///
struct BlazePaymentInfoMapper: Mapper {

    /// (Attempts) to convert a dictionary into `BlazePaymentInfo`.
    ///
    func map(response: Data) throws -> BlazePaymentInfo {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(BlazePaymentInfo.self, from: response)
    }
}
