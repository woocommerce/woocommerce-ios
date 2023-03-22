import Foundation
import struct Yosemite.WPComSitePlan

/// Extension to determine if a WPComPlan is a free trial plan.
///
extension WPComSitePlan {

    /// WooCommerce Core Free Trial ID.
    ///
    private static let freeTrialID = "1052"

    /// Determines if a plan is a free trial plan.
    /// Note: It doesn't take into account if the trial has expired or not.
    ///
    var isFreeTrial: Bool {
        id == Self.freeTrialID && expiryDate != nil
    }
}
