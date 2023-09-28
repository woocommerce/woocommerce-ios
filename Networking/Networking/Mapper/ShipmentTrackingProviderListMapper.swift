import Foundation

/// (Attempts) to convert a dictionary into an ShipmentTrackingProviderGroup entity.
///
struct ShipmentTrackingProviderListMapper: Mapper {

    private let siteID: Int64

    public init(siteID: Int64) {
        self.siteID = siteID
    }

    private typealias RawData = [String: [String: String]]

    func map(response: Data) throws -> [ShipmentTrackingProviderGroup] {
        let decoder = JSONDecoder()
        let rawDictionary: RawData
        if hasDataEnvelope(in: response) {
            rawDictionary = try decoder.decode(Envelope<RawData>.self, from: response).data
        } else {
            rawDictionary = try decoder.decode(RawData.self, from: response)
        }
        return rawDictionary.map({ ShipmentTrackingProviderGroup(name: $0.key, siteID: siteID, dictionary: $0.value) })
    }
}
