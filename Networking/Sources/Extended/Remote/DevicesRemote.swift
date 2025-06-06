import Foundation


/// Devices: Remote Endpoints (Push Notifications Registration / Unregistration!)
///
public class DevicesRemote: Remote {

    /// Registers a device for Push Notifications Delivery.
    ///
    /// - Parameters:
    ///     - device: APNS Device to be registered.
    ///     - applicationId: App ID.
    ///     - applicationVersion: App Version.
    ///     - defaultStoreID: Active Store ID.
    /// - Returns: The registered device.
    /// - Throws: Error if the request fails.
    ///
    public func registerDevice(device: APNSDevice,
                               applicationId: String,
                               applicationVersion: String,
                               defaultStoreID: Int64) async throws -> DotcomDevice {
        var parameters = [
            ParameterKeys.applicationId: applicationId,
            ParameterKeys.applicationVersion: applicationVersion,
            ParameterKeys.deviceFamily: device.family,
            ParameterKeys.deviceToken: device.token,
            ParameterKeys.deviceModel: device.model,
            ParameterKeys.deviceName: device.name,
            ParameterKeys.deviceOSVersion: device.iOSVersion,
            ParameterKeys.defaultStoreID: ""
        ]

        if let deviceUUID = device.identifierForVendor {
            parameters[ParameterKeys.deviceUUID] = deviceUUID
        }

        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .post, path: Paths.register, parameters: parameters)
        let mapper = DotcomDeviceMapper()

        return try await enqueue(request, mapper: mapper)
    }


    /// Removes a given DeviceId from the Push Notifications systems.
    ///
    /// - Parameters:
    ///     - deviceId: Identifier of the device to be removed.
    /// - Throws: Error if the request fails.
    ///
    public func unregisterDevice(deviceId: String) async throws {
        let path = String(format: Paths.delete, deviceId)
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .post, path: path)
        let mapper = SuccessResultMapper()

        let success = try await enqueue(request, mapper: mapper)
        guard success == true else {
            throw DotcomError.empty
        }
    }
}


// MARK: - Constants!
//
private extension DevicesRemote {

    enum Paths {
        static let register = "devices/new"
        static let delete = "devices/%@/delete"
    }

    enum ParameterKeys {
        static let applicationId = "app_secret_key"
        static let applicationVersion = "app_version"
        static let deviceFamily = "device_family"
        static let deviceToken = "device_token"
        static let deviceModel = "device_model"
        static let deviceName = "device_name"
        static let deviceOSVersion = "os_version"
        static let deviceUUID = "device_uuid"
        static let defaultStoreID = "selected_blog_id"
    }
}
