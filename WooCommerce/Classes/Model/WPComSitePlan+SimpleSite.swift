import Foundation
import struct Yosemite.WPComSitePlan

/// Extension to determine if a WPComPlan is a free WordPress plan.
///
extension WPComSitePlan {

    /// WooCommerce Core Free Trial ID.
    ///
    private static let freePlan = "1"

    /// Determines if a plan is a free plan.
    /// Note: It doesn't take into account if the trial has expired or not.
    ///
    var isFreePlan: Bool {
        id == Self.freePlan
    }
}
