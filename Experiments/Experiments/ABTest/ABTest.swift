import AutomatticTracks

/// ABTest adds A/B testing experiments and runs the tests based on their variations from the ExPlat service.
///
public enum ABTest: String, CaseIterable {
    case loginOnboarding = "wcios_login_onboarding_variant"
}

public typealias Variation = AutomatticTracks.Variation

public protocol ABTesting {
    /// Starts the AB Testing platform if any experiment exists.
    func start()

    /// Refreshes the assigned experiments.
    func refresh() async

    /// Return an experiment variation for a given AB test.
    func variation(for test: ABTest) -> Variation

    /// Logs an event for measuring or activating an AB test.
    /// - Parameter event: an event to activate or measure an AB test.
    func logEvent(_ event: ABTestEvent)
}

public struct ABTestEvent {
    public let name: String
    public let properties: [String: String]

    public init(name: ABTestEventName, properties: [String: String] = [:]) {
        self.name = name.rawValue
        self.properties = properties
    }
}

public enum ABTestEventName: String {
    // Activation.
    case loginOnboardingShown = "login_onboarding_shown"
    // Metrics.
    case siteShown = "site_shown"
    case loginSuccess = "login_success"
}
