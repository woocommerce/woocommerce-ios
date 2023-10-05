import Foundation

struct WooPaymentsDepositsOverviewMapper: Mapper {
    func map(response: Data) throws -> WooPaymentsDepositsOverview {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970

        if hasDataEnvelope(in: response) {
            return try decoder.decode(WooPaymentsDepositsOverviewEnvelope.self, from: response).depositsOverview
        } else {
            return try decoder.decode(WooPaymentsDepositsOverview.self, from: response)
        }
    }
}

private struct WooPaymentsDepositsOverviewEnvelope: Decodable {
    let depositsOverview: WooPaymentsDepositsOverview

    private enum CodingKeys: String, CodingKey {
        case depositsOverview = "data"
    }
}
