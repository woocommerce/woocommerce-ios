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

    /// A/B test to measure the sign-in success rate when only WPCom login is enabled.
    /// Experiment ref: pbxNRc-27s-p2
    ///
    case abTestLoginWithWPComOnly = "woocommerceios_login_wpcom_only"

    /// A/B test to measure the sign-in success rate when native Jetpack installation experience is enabled
    /// Experiment ref: pbxNRc-29W-p2
    ///
    case nativeJetpackSetupFlow = "woocommerceios_login_jetpack_setup_flow_v2"

    /// A/B test for the Products Onboarding banner on the My Store dashboard.
    /// Experiment ref: pbxNRc-26F-p2
    case productsOnboardingBanner = "woocommerceios_products_onboarding_first_product_banner"

    /// A/B test for the Products Onboarding product creation type bottom sheet after tapping the "Add Product" CTA.
    /// Experiment ref: pbxNRc-28r-p2
    case productsOnboardingTemplateProducts = "woocommerceios_products_onboarding_template_products"

    /// Returns a variation for the given experiment
    public var variation: Variation {
        ExPlat.shared?.experiment(rawValue) ?? .control
    }

    /// Returns the context for the given experiment.
    ///
    /// When adding a new experiment, add it to the appropriate case depending on its context (logged-in or logged-out experience).
    public var context: ExperimentContext {
        switch self {
        case .aaTestLoggedIn, .productsOnboardingBanner, .productsOnboardingTemplateProducts, .nativeJetpackSetupFlow:
            return .loggedIn
        case .aaTestLoggedOut, .abTestLoginWithWPComOnly:
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

/// The context for an A/B testing experiment (where the experience being tested occurs).
///
public enum ExperimentContext: Equatable {
    case loggedOut
    case loggedIn
    case none // For the `null` experiment case
}
