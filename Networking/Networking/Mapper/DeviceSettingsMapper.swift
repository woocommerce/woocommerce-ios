import Foundation


/// Mapper: Notifications List
///
struct DeviceSettingsMapper: Mapper {

    /// (Attempts) to convert an instance of Data into an array of Note Entities.
    ///
    func map(response: Data) throws -> DeviceSettings {
        return try JSONDecoder().decode(DeviceSettings.self, from: response)
    }
}
