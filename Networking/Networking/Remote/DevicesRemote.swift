import Foundation
import Alamofire


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
    ///     - completion: Closure to be executed on commpletion.
    ///
    public func registerDevice(device: APNSDevice,
                               applicationId: String,
                               applicationVersion: String,
                               defaultStoreID: Int64,
                               completion: @escaping (DotcomDevice?, Error?) -> Void) {
        var parameters = [
            ParameterKeys.applicationId: applicationId,
            ParameterKeys.applicationVersion: applicationVersion,
            ParameterKeys.deviceFamily: device.family,
            ParameterKeys.deviceToken: device.token,
            ParameterKeys.deviceModel: device.model,
            ParameterKeys.deviceName: device.name,
            ParameterKeys.deviceOSVersion: device.iOSVersion,
            ParameterKeys.defaultStoreID: String(defaultStoreID)
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
    ///     - completion: Closure to be executed on commpletion.
    ///
    public func unregisterDevice(deviceId: String, completion: @escaping (Error?) -> Void) {
        let path = String(format: Paths.delete, deviceId)
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .post, path: path)
        let mapper = SuccessResultMapper()

        enqueue(request, mapper: mapper) { (success, error) in
            guard success == true else {
                completion(error ?? DotcomError.empty)
                return
            }

            completion(nil)
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
