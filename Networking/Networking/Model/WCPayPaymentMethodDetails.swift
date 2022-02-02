import Foundation
import Codegen

// https://stripe.com/docs/api/charges/object#charge_object-payment_method_details
public enum WCPayPaymentMethodDetails: Decodable, GeneratedCopiable, GeneratedFakeable, Equatable {
    case card(details: WCPayCardPaymentDetails)
    case cardPresent(details: WCPayCardPresentPaymentDetails)
    case unknown

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        guard let type = try? container.decode(WCPayPaymentMethodType.self, forKey: .type) else {
            self = .unknown
            return
        }

        switch type {
        case .card:
            guard let cardDetails = try? container.decode(WCPayCardPaymentDetails.self, forKey: .card) else {
                throw WCPayPaymentMethodDetailsDecodingError.noDetailsPresentForPaymentType
            }
            self = .card(details: cardDetails)
        case .cardPresent:
            guard let cardPresentDetails = try? container.decode(WCPayCardPresentPaymentDetails.self, forKey: .cardPresent) else {
                throw WCPayPaymentMethodDetailsDecodingError.noDetailsPresentForPaymentType
            }
            self = .cardPresent(details: cardPresentDetails)
        case .unknown:
            self = .unknown
        }
    }
}

internal extension WCPayPaymentMethodDetails {
    enum CodingKeys: String, CodingKey {
        case type
        case card
        case cardPresent = "card_present"
    }
}

enum WCPayPaymentMethodDetailsDecodingError: Error {
    case noDetailsPresentForPaymentType
}
