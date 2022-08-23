import AutomatticTracks

/// ABTest adds A/B testing experiments and runs the tests based on their variations from the ExPlat service.
///
public enum ABTest: String, CaseIterable {
    /// Throwaway case, to prevent a compiler error:
    /// `An enum with no cases cannot declare a raw type`
    case null

    /// A/A test for ExPlat integration.
    /// Experiment ref: pbxNRc-1QS-p2
    ///
    case aaTest202208 = "woocommerceios_explat_aa_test_202208"

    /// A/A test to make sure there is no bias in the logged out state.
    /// Experiment ref: pbxNRc-1S0-p2
    case aaTestLoggedOut202208 = "woocommerceios_explat_aa_test_logged_out_202208"

    /// A/B test for promoting linked products in Product Details.
    /// Experiment ref: pbxNRc-1Pp-p2
    case linkedProductsPromo = "woocommerceios_product_details_linked_products_banner"

    /// Returns a variation for the given experiment
    public var variation: Variation {
        ExPlat.shared?.experiment(rawValue) ?? .control
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
