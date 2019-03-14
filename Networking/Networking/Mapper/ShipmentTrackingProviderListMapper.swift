import Foundation

/// (Attempts) to convert a dictionary into an ShipmentTrackingProviderGroup entity.
///
struct ShipmentTrackingProviderListMapper: Mapper {
    func map(response: Data) throws -> [ShipmentTrackingProviderGroup] {
        let decoder = JSONDecoder()
        let rawDictionary = try? decoder.decode(ShipmentTrackingProviderListEnvelope.self, from: response).rawData
        return rawDictionary?.map({ ShipmentTrackingProviderGroup(name: $0.key, dictionary: $0.value) }) ?? []
    }
}


/// ShipmentTrackingProviderListEnvelope Disposable Entity: The shipment tracking provider endpoint returns
/// the providers within a `data` key.
///
private struct ShipmentTrackingProviderListEnvelope: Decodable {
    let rawData: [String: [String: String]]

    private enum CodingKeys: String, CodingKey {
        case rawData = "data"
    }
}
