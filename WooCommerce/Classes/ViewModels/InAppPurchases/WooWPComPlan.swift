import Yosemite

public struct WooWPComPlan: Identifiable {
    let wpComPlan: WPComPlanProduct
    let wooPlan: WooPlan
    let hardcodedPlanDataIsValid: Bool

    public var id: String {
        return wpComPlan.id
    }
}
