/// Mapper: NewShipmentTrackingMapper
///
final class NewShipmentTrackingMapper: Mapper {
    /// (Attempts) to convert a dictionary into an ShipmentTracking entity.
    ///
    func map(response: Data) throws -> ShipmentTracking {
        let decoder = JSONDecoder()
        return try decoder.decode(ShipmentTracking.self, from: response)
    }
}
