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
    ///     - completion: Closure to be executed on completion.
    ///
    public func registerDevice(device: APNSDevice,
                               applicationId: String,
                               applicationVersion: String,
                               completion: @escaping (DotcomDevice?, Error?) -> Void) {
        var parameters = [
            ParameterKeys.applicationId: applicationId,
            ParameterKeys.applicationVersion: applicationVersion,
            ParameterKeys.deviceFamily: device.family,
            ParameterKeys.deviceToken: device.token,
            ParameterKeys.deviceModel: device.model,
            ParameterKeys.deviceName: device.name,
            ParameterKeys.deviceOSVersion: device.iOSVersion,
        ]

        if let deviceUUID = device.identifierForVendor {
            parameters[ParameterKeys.deviceUUID] = deviceUUID
        }

        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .post, path: Paths.register, parameters: parameters)
        let mapper = DotcomDeviceMapper()

        enqueue(request, mapper: mapper) { (device, error) in
            completion(device, error)
        }
    }


    /// Removes a given DeviceId from the Push Notifications systems.
    ///
    /// - Parameters:
    ///     - deviceId: Identifier of the device to be removed.
    ///     - completion: Closure to be executed on completion.
    ///
    public func unregisterDevice(deviceId: String, completion: @escaping (Error?) -> Void) {
        let path = String(format: Paths.delete, deviceId)
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .post, path: path)
        let mapper = SuccessResultMapper()

        enqueue(request, mapper: mapper) { (success, error) in
            guard success == true else {
                completion(error ?? DotcomError.empty())
                return
            }

            completion(nil)
        }
    }

    /// Registers a device for Push Notifications Delivery with the self-driven push notification system.
    ///
    /// - Parameters:
    ///     - siteID: ID of the site
    ///     - device: APNS Device to be registered.
    ///     - applicationId: App ID.
    /// - Returns: The unique ID of the push token record
    ///
    public func registerForSelfDrivenPushNotifications(siteID: Int64,
                                                       device: APNSDevice,
                                                       applicationID: String) async throws -> Int64 {
        var parameters = [
            ParameterKeys.origin: applicationID,
            ParameterKeys.token: device.token,
            ParameterKeys.platform: Values.platform
        ]

        if let deviceUUID = device.identifierForVendor {
            parameters[ParameterKeys.deviceUUID] = deviceUUID
        }

        let request = JetpackRequest(wooApiVersion: .none,
                                     method: .post,
                                     siteID: siteID,
                                     path: Paths.selfDrivenPN,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        let mapper = TokenIDMapper()
        return try await enqueue(request, mapper: mapper)
    }

    /// Removes a given tokenID from the the self-driven push notification system.
    ///
    /// - Parameters:
    ///     - siteID: ID of the site
    ///     - tokenID: The push token ID to delete
    ///
    public func unregisterFromSelfDrivenPushNotifications(siteID: Int64,
                                                          tokenID: Int64) async throws {
        let path = Paths.selfDrivenPN + "/\(tokenID)"
        let request = JetpackRequest(wooApiVersion: .none,
                                     method: .delete,
                                     siteID: siteID,
                                     path: path,
                                     availableAsRESTRequest: true)
        try await enqueue(request)
    }
}


// MARK: - Constants!
//
private extension DevicesRemote {
    enum Values {
        static let platform = "ios"
    }

    enum Paths {
        static let register = "devices/new"
        static let delete = "devices/%@/delete"
        static let selfDrivenPN = "wc-push-notifications/push-tokens"
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
        static let token = "token"
        static let platform = "platform"
        static let origin = "origin"
    }
}
