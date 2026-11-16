import Foundation

struct OrderPaymentDetailsMapper: Mapper {
    func map(response: Data) throws -> OrderPaymentDetails {
        if hasDataEnvelope(in: response) {
            return try JSONDecoder().decode(Envelope.self, from: response).data
        }
        return try JSONDecoder().decode(OrderPaymentDetails.self, from: response)
    }

    private struct Envelope: Decodable {
        let data: OrderPaymentDetails
    }
}
