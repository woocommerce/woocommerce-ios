import Foundation


/// Mapper: Dotcom Device
///
struct DotcomDeviceMapper: Mapper {

    /// (Attempts) to convert an instance of Data into an array of Note Entities.
    ///
    func map(response: Data) throws -> DotcomDevice {
        return try JSONDecoder().decode(DotcomDevice.self, from: response)
    }
}
