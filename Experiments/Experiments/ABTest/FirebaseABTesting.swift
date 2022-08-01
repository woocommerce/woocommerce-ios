import FirebaseCore
import FirebaseAnalytics
import FirebaseRemoteConfig
import FirebaseInstallations

public class FirebaseABTesting: ABTesting {
    /// `RemoteConfig` is set as a variable instead of a constant because `FirebaseApp.configure()` needs to be called before `RemoteConfig.remoteConfig()`.
    private lazy var remoteConfig: RemoteConfig = RemoteConfig.remoteConfig()

    public init() {
    }

    @MainActor
    public func start() {
        guard isSupported() else {
            return
        }

        FirebaseApp.configure()

        Installations.installations().authTokenForcingRefresh(true, completion: { (result, error) in
            if let error = error {
                print("Error fetching token: \(error)")
                return
            }
            guard let result = result else { return }
            print("Installation auth token: \(result.authToken)")
        })

        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings

        Task {
            do {
                try await remoteConfig.fetchAndActivate()
            } catch {

            }
        }
    }

    public func refresh() async {

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
    func isSupported() -> Bool {
        Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
    }
}

private extension ABTest {
    func variation(from value: RemoteConfigValue) -> Variation {
        switch self {
        case .loginOnboarding:
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
}
