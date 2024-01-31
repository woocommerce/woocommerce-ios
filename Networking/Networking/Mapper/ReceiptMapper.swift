import Foundation

struct ReceiptMapper: Mapper {
    /// (Attempts) to convert a dictionary into `Receipt`.
    ///
    func map(response: Data) throws -> Receipt {
        let decoder = JSONDecoder()
        if hasDataEnvelope(in: response) {
            return try decoder.decode(ReceiptEnvelope.self, from: response).data
        } else {
            return try decoder.decode(Receipt.self, from: response)
        }
    }
}

/// `ReceiptEnvelope` allows us to parse all the things with JSONDecoder.
///
private struct ReceiptEnvelope: Decodable {
    let data: Receipt
}
