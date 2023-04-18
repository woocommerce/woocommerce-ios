import Foundation
import struct Yosemite.WPComSitePlan

/// Type to help sanitize and format a WPCom site plan name.
///
struct WPComPlanNameSanitizer {
    /// Removes any occurrences of `WordPress.com` and `Woo Express:` from the site's name.
    /// Free Trial's sites have an special handling!
    ///
    static func getPlanName(from plan: WPComSitePlan) -> String {
        // Handle the "Free trial" case specially.
        if plan.isFreeTrial {
            return Localization.freeTrial
        }

        // For non-free trials plans remove any mention to WPCom or Woo Express.
        let toRemove = ["WordPress.com", "Woo Express:"]
        let sanitizedName = toRemove.reduce(plan.name) { planName, prefixToRemove in
            planName.replacingOccurrences(of: prefixToRemove, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return sanitizedName
    }
}

// MARK: Constants
private extension WPComPlanNameSanitizer {
    enum Localization {
        static let freeTrial = NSLocalizedString("Free Trial", comment: "Plan name for an active free trial")
    }
}
