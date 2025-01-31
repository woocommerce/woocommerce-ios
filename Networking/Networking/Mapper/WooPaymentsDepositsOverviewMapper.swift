import Foundation

struct WooPaymentsPayoutsOverviewMapper: Mapper {
    func map(response: Data) throws -> WooPaymentsPayoutsOverview {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970

        if hasDataEnvelope(in: response) {
            return try decoder.decode(WooPaymentsPayoutsOverviewEnvelope.self, from: response).payoutsOverview
        } else {
            return try decoder.decode(WooPaymentsPayoutsOverview.self, from: response)
        }
    }
}

private struct WooPaymentsPayoutsOverviewEnvelope: Decodable {
    let payoutsOverview: WooPaymentsPayoutsOverview

    private enum CodingKeys: String, CodingKey {
        case payoutsOverview = "data"
    }
}
