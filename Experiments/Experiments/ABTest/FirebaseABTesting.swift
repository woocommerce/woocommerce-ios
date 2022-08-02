import FirebaseCore
import FirebaseAnalytics
import FirebaseRemoteConfig

/// Configures A/B testing using Firebase Remote Config and provides the variation for each A/B test.
public class FirebaseABTesting: ABTesting {
    /// `RemoteConfig` is set as a variable instead of a constant because `FirebaseApp.configure()` needs to be called before `RemoteConfig.remoteConfig()`.
    private lazy var remoteConfig: RemoteConfig = RemoteConfig.remoteConfig()

    public init() {}

    @MainActor
    public func start() {
        guard isSupported() else {
            return
        }

        FirebaseApp.configure()

        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings

        Task {
            do {
                try await remoteConfig.fetchAndActivate()
            } catch {
                print("Error fetching and activating remote config: \(error)")
            }
        }
    }

    public func refresh() async {
        // no-op
    }

    public func variation(for test: ABTest) -> Variation {
        guard isSupported() else {
            return .control
        }

        let value = remoteConfig.configValue(forKey: test.rawValue)
        return test.variation(from: value)
    }

    public func logEvent(_ event: ABTestEvent) {
        guard isSupported() else {
            return
        }

        Analytics.logEvent(event.name, parameters: event.properties)
    }
}

private extension FirebaseABTesting {
    /// Firebase is only supported if `GoogleService-Info.plist` exists in the bundle and has a non-empty client ID.
    /// - Returns: a boolean that indicates whether Firebase is supported for A/B testing.
    func isSupported() -> Bool {
        let bundle = Bundle(for: Self.self)
        guard let url = bundle.url(forResource: "GoogleService-Info", withExtension: "plist") else {
            return false
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = PropertyListDecoder()
            let googleServiceInfo = try decoder.decode(GoogleServiceInfo.self, from: data)
            return googleServiceInfo.clientID.isEmpty == false
        } catch {
            return false
        }
    }
}

/// Follows the structure of `GoogleService-Info.plist`.
private struct GoogleServiceInfo: Decodable {
    let clientID: String

    private enum CodingKeys: String, CodingKey {
        case clientID = "CLIENT_ID"
    }
}

private extension ABTest {
    func variation(from value: RemoteConfigValue) -> Variation {
        switch self {
        case .loginOnboarding:
            return loginOnboardingVariation(from: value)
        }
    }

    func loginOnboardingVariation(from value: RemoteConfigValue) -> Variation {
        guard let value = value.stringValue else {
            return .control
        }
        switch value {
        case "control":
            return .control
        case "survey":
            return .treatment("survey")
        default:
            return .control
        }
    }
}
