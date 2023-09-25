import Foundation

struct WCPayDepositsOverviewMapper: Mapper {
    func map(response: Data) throws -> WCPayDepositsOverview {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970

        if hasDataEnvelope(in: response) {
            return try decoder.decode(WCPayDepositsOverviewEnvelope.self, from: response).depositsOverview
        } else {
            return try decoder.decode(WCPayDepositsOverview.self, from: response)
        }
    }
}

private struct WCPayDepositsOverviewEnvelope: Decodable {
    let depositsOverview: WCPayDepositsOverview

    private enum CodingKeys: String, CodingKey {
        case depositsOverview = "data"
    }
}
