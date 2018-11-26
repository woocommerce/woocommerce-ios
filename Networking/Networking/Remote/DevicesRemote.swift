import Foundation
import Alamofire


/// Devices: Remote Endpoints (Push Notifications Registration / Unregistration!)
///
public class DevicesRemote: Remote {

    /// - Parameters:
    ///     - deviceToken: APNS Token to be registered.
    ///     - deviceModel: Model of the device to be registered.
    ///     - deviceName: Name of the device to be registered.
    ///     - deviceOSVersion: iOS Version
    ///     - deviceUUID: Unique Device Identifier
    ///     - applicationId: Identifier of the App
    ///     - applicationVersion: App Version.
    ///     - completion: Closure to be executed on commpletion.
    ///
    public func registerDevice(deviceToken: String,
                               deviceModel: String,
                               deviceName: String,
                               deviceOSVersion: String,
                               deviceUUID: String?,
                               applicationId: String,
                               applicationVersion: String,
                               completion: @escaping (DeviceSettings?, Error?) -> Void) {

        var parameters = [
            ParameterKeys.applicationId: applicationId,
            ParameterKeys.applicationVersion: applicationVersion,
            ParameterKeys.deviceFamily: Constants.defaultDeviceFamily,
            ParameterKeys.deviceToken: deviceToken,
            ParameterKeys.deviceModel: deviceModel,
            ParameterKeys.deviceName: deviceName,
            ParameterKeys.deviceOSVersion: deviceOSVersion
        ]

        if let deviceUUID = deviceUUID {
            parameters[ParameterKeys.deviceUUID] = deviceUUID
        }

        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .post, path: Paths.register, parameters: parameters)
        let mapper = DeviceSettingsMapper()

        enqueue(request, mapper: mapper) { (settings, error) in
            completion(settings, error)
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
                completion(error ?? DotcomError.unknown)
                return
            }

            completion(nil)
        }
    }
}


// MARK: - Constants!
//
private extension DevicesRemote {

    enum Constants {
        static let defaultDeviceFamily = "apple"
    }

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
    }
}
