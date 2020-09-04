import Foundation

/// Feature Flags: Remote Endpoints
///
public class FeatureFlagsRemote: Remote {

    public typealias FetchResponse = (Result<FeatureFlagList, Error>) -> Void

    public func loadAllFeatureFlags(forDeviceId deviceId: String, completion: @escaping FetchResponse) {

        let parameters: [String: String] = [
            ParameterKeys.deviceId: deviceId,
            ParameterKeys.platform: "apple",
            ParameterKeys.buildNumber: Bundle.main.buildNumber,
            ParameterKeys.marketingVersion: Bundle.main.marketingVersion,
            ParameterKeys.bundleIdentifier: Bundle.main.bundleIdentifier ?? "unknown",
        ]

        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2, method: .get, path: Paths.lookup, parameters: parameters)
        let mapper = FeatureFlagMapper()
        enqueue(request, mapper: mapper, completion: completion)
    }
}

// MARK: - Constants!
//
private extension FeatureFlagsRemote {

    enum Paths {
        static let lookup = "mobile/feature-flags"
    }

    enum ParameterKeys {
        static let deviceId = "device_id"
        static let platform = "platform"
        static let buildNumber = "build_number"
        static let marketingVersion = "marketing_version"
        static let bundleIdentifier = "bundle_identifier"
    }
}
