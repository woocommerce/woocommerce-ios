import Foundation

/// Protocol for `FeatureFlagsRemote` mainly used for mocking.
///
public protocol FeatureFlagRemoteProtocol {
    func loadAllFeatureFlags() async throws -> [RemoteFeatureFlag: Bool]
}

/// Feature Flags: Remote Endpoints
///
public class FeatureFlagRemote: Remote, FeatureFlagRemoteProtocol {
    public func loadAllFeatureFlags() async throws -> [RemoteFeatureFlag: Bool] {
        let parameters: [String: String] = [
            ParameterKeys.platform: "ios",
            ParameterKeys.marketingVersion: Bundle.main.marketingVersion,
        ]

        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2, method: .get, path: Paths.lookup, parameters: parameters)
        let valuesByFeatureFlagString: [String: Bool] = try await enqueue(request)
        return Dictionary(uniqueKeysWithValues: valuesByFeatureFlagString.compactMap { key, value in
            guard let featureFlag = RemoteFeatureFlag(rawValue: key) else {
                return nil
            }
            return (featureFlag, value)
        })
    }
}

public enum RemoteFeatureFlag: Decodable {
    case storeCreationCompleteNotification
    case oneDayAfterStoreCreationNameWithoutFreeTrial
    case oneDayBeforeFreeTrialExpiresNotification
    case oneDayAfterFreeTrialExpiresNotification

    init?(rawValue: String) {
        switch rawValue {
        case "woo_notification_store_creation_ready":
            self = .storeCreationCompleteNotification
        case "woo_notification_nudge_free_trial_after_1d":
            self = .oneDayAfterStoreCreationNameWithoutFreeTrial
        case "woo_notification_1d_before_free_trial_expires":
            self = .oneDayBeforeFreeTrialExpiresNotification
        case "woo_notification_1d_after_free_trial_expires":
            self = .oneDayAfterFreeTrialExpiresNotification
        default:
            return nil
        }
    }
}

// MARK: - Constants!
//
private extension FeatureFlagRemote {
    enum Paths {
        static let lookup = "mobile/feature-flags"
    }

    enum ParameterKeys {
        static let platform = "platform"
        static let marketingVersion = "marketing_version"
    }
}
