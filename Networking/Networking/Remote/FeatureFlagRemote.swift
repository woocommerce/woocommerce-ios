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
    case hardcodedPlanUpgradeDetailsMilestone1AreAccurate

    init?(rawValue: String) {
        switch rawValue {
        case "woo_notification_store_creation_ready":
            self = .storeCreationCompleteNotification
        case "woo_hardcoded_plan_upgrade_details_milestone_1_are_accurate":
            self = .hardcodedPlanUpgradeDetailsMilestone1AreAccurate
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
