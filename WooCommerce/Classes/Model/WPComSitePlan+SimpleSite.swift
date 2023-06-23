import Foundation
import struct Yosemite.WPComSitePlan

/// Extension to determine if a WPComPlan is a free WordPress plan.
///
extension WPComSitePlan {

    /// WooCommerce Core Free WordPress plan ID.
    ///
    private static let freePlan = "1"

    /// Determines if a plan is a free plan.
    ///
    var isFreePlan: Bool {
        id == Self.freePlan
    }
}
