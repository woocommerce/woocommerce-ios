import Foundation
import Codegen

public struct Receipt: Decodable, GeneratedFakeable, GeneratedCopiable {
    public let receiptURL: String
    public let expirationDate: String

    public init(receiptURL: String, expirationDate: String) {
        self.receiptURL = receiptURL
        self.expirationDate = expirationDate
    }

    public init(from decoder: Decoder) throws {
         let container = try decoder.container(keyedBy: CodingKeys.self)

         let decodedReceiptURL = try container.decode(String.self, forKey: .receiptURL)
         let decodedExpirationDate = try container.decode(String.self, forKey: .expirationDate)

         self.init(receiptURL: decodedReceiptURL, expirationDate: decodedExpirationDate)
     }
}

extension Receipt {
    enum CodingKeys: String, CodingKey {
        case receiptURL = "receipt_url"
        case expirationDate = "expiration_date"
    }
}
