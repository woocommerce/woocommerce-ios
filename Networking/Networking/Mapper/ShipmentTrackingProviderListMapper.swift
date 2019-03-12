struct ShipmentTrackingProviderListMapper: Mapper {
    /// (Attempts) to convert a dictionary into an ShipmentTracking entity.
    ///
    func map(response: Data) throws -> [ShipmentTrackingProviderGroup] {
        let decoder = JSONDecoder()
        return try decoder.decode(ShipmentTrackingProviderGroupEnvelope.self, from: response).groups
    }
}

private struct ShipmentTrackingProviderGroupEnvelope: Decodable {
    let groups: [ShipmentTrackingProviderGroup]
}
