import AutomatticTracks

/// ABTest adds A/B testing experiments and runs the tests based on their variations from the ExPlat service.
///
public enum ABTest: String, CaseIterable {
    /// Throwaway case, to prevent a compiler error:
    /// `An enum with no cases cannot declare a raw type`
    case null

    /// A/A test for ExPlat integration in the logged in state.
    /// Experiment ref: pbxNRc-1QS-p2
    ///
    case aaTest202209 = "woocommerceios_explat_aa_test_logged_in_202209"

    /// A/A test to make sure there is no bias in the logged out state.
    /// Experiment ref: pbxNRc-1S0-p2
    case aaTestLoggedOut202209 = "woocommerceios_explat_aa_test_logged_out_202209"

    /// A/B test for the login button order on the prologues screen.
    /// Experiment ref: pbxNRc-1VA-p2
    case loginPrologueButtonOrder = "woocommerceios_login_prologue_button_order_202209"

    /// Returns a variation for the given experiment
    public var variation: Variation {
        ExPlat.shared?.experiment(rawValue) ?? .control
    }

    /// Returns the context for the given experiment.
    ///
    /// When adding a new experiment, add it to the appropriate case depending on its context (logged-in or logged-out experience).
    public var context: ExperimentContext {
        switch self {
        case .aaTest202209:
            return .loggedIn
        case .aaTestLoggedOut202209, .loginPrologueButtonOrder:
            return .loggedOut
        case .null:
            return .none
        }
    }
}

public extension ABTest {
    /// Start the AB Testing platform if any experiment exists
    ///
    static func start() async {
        await withCheckedContinuation { continuation in
            guard ABTest.allCases.count > 1 else {
                return continuation.resume(returning: ())
            }

            let experimentNames = ABTest.allCases.filter { $0 != .null }.map { $0.rawValue }
            ExPlat.shared?.register(experiments: experimentNames)

            ExPlat.shared?.refresh {
                continuation.resume(returning: ())
            }
        } as Void
    }
}

public extension Variation {
    /// Used in an analytics event property value.
    var analyticsValue: String {
        switch self {
        case .control:
            return "control"
        case .treatment(let string):
            return string.map { "treatment: \($0)" } ?? "treatment"
        }
    }
}

public enum ExperimentContext: Equatable {
    case loggedOut
    case loggedIn
    case none // For the `null` experiment case
}
