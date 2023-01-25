import Foundation

/// (Attempts) to convert a dictionary into an ShipmentTrackingProviderGroup entity.
///
struct ShipmentTrackingProviderListMapper: Mapper {
    private let siteID: Int64

    public init(siteID: Int64) {
        self.siteID = siteID
    }

    func map(response: Data) throws -> [ShipmentTrackingProviderGroup] {
        let decoder = JSONDecoder()
        let rawDictionary: ShipmentTrackingProviderListEnvelope.RawData
        do {
            rawDictionary = try decoder.decode(ShipmentTrackingProviderListEnvelope.self, from: response).rawData
        } catch {
            rawDictionary = try decoder.decode(ShipmentTrackingProviderListEnvelope.RawData.self, from: response)
        }
        return rawDictionary.map({ ShipmentTrackingProviderGroup(name: $0.key, siteID: siteID, dictionary: $0.value) })
    }
}


/// ShipmentTrackingProviderListEnvelope Disposable Entity: The shipment tracking provider endpoint returns
/// the providers within a `data` key.
///
private struct ShipmentTrackingProviderListEnvelope: Decodable {
    typealias RawData = [String: [String: String]]

    let rawData: RawData

    private enum CodingKeys: String, CodingKey {
        case rawData = "data"
    }
}
