import Yosemite

public struct WooWPComPlan: Identifiable {
    let wpComPlan: WPComPlanProduct
    let wooPlan: WooPlan
    let hardcodedPlanDataIsValid: Bool

    public var id: String {
        return wpComPlan.id
    }

    public var shouldDisplayIsPopularBadge: Bool {
        let popularPlans =  [
            AvailableInAppPurchasesWPComPlans.performanceMonthly.rawValue,
            AvailableInAppPurchasesWPComPlans.performanceYearly.rawValue
        ]
        return popularPlans.contains(where: { $0 == wpComPlan.id })
    }
}
