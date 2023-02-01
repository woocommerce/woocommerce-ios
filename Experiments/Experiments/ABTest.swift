import AutomatticTracks

/// ABTest adds A/B testing experiments and runs the tests based on their variations from the ExPlat service.
///
public enum ABTest: String, CaseIterable {
    /// Throwaway case, to prevent a compiler error:
    /// `An enum with no cases cannot declare a raw type`
    case null

    /// A/A test to make sure there is no bias in the logged out state.
    /// Experiment ref: pbxNRc-1QS-p2
    case aaTestLoggedIn = "woocommerceios_explat_aa_test_logged_in_202212_v2"

    /// A/A test to make sure there is no bias in the logged out state.
    /// Experiment ref: pbxNRc-1S0-p2
    case aaTestLoggedOut = "woocommerceios_explat_aa_test_logged_out_202212_v2"

    /// A/B test for the REST API project
    /// Experiment ref: pbxNRc-2i4-p2
    case applicationPasswordAuthentication = "woocommerceios_login_rest_api_project_202301_v2"

    /// Returns a variation for the given experiment
    public var variation: Variation {
        ExPlat.shared?.experiment(rawValue) ?? .control
    }

    /// Returns the context for the given experiment.
    ///
    /// When adding a new experiment, add it to the appropriate case depending on its context (logged-in or logged-out experience).
    public var context: ExperimentContext {
        switch self {
        case .aaTestLoggedIn:
            return .loggedIn
        case .aaTestLoggedOut, .applicationPasswordAuthentication:
            return .loggedOut
        case .null:
            return .none
        }
    }
}

public extension ABTest {
    /// Start the AB Testing platform if any experiment exists for the provided context
    ///
    @MainActor
    static func start(for context: ExperimentContext) async {
        let experiments = ABTest.allCases.filter { $0.context == context }
        await start(experiments: experiments)
    }

    /// Start the AB Testing platform for all experiments
    ///
    @MainActor
    static func start() async {
        let experiments = ABTest.allCases
        await start(experiments: experiments)
    }
}

public extension Variation {
    /// Used in an analytics event property value.
    var analyticsValue: String {
        switch self {
        case .control:
            return "control"
        case .treatment:
            return "treatment"
        case .customTreatment(let name):
            return "treatment: \(name)"
        }
    }
}

/// The context for an A/B testing experiment (where the experience being tested occurs).
///
public enum ExperimentContext: Equatable {
    case loggedOut
    case loggedIn
    case none // For the `null` experiment case
}

private extension ABTest {
    /// Start the AB Testing platform using the given `experiments`
    ///
    @MainActor
    static func start(experiments: [ABTest]) async {
        await withCheckedContinuation { continuation in
            guard !experiments.isEmpty else {
                return continuation.resume(returning: ())
            }

            let experimentNames = experiments.map { $0.rawValue }
            ExPlat.shared?.register(experiments: experimentNames)

            ExPlat.shared?.refresh {
                continuation.resume(returning: ())
            }
        } as Void
    }
}
