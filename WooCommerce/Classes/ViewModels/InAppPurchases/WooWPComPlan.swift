import Yosemite

public struct WooWPComPlan: Identifiable {
    let wpComPlan: WPComPlanProduct
    let wooPlan: LegacyWooPlan
    let hardcodedPlanDataIsValid: Bool

    public var id: String {
        return wpComPlan.id
    }
}
