import Foundation
import SwiftUI

public struct LegacyWooPlan: Decodable {
    public let id: String
    public let name: String
    public let shortName: String
    public let planFrequency: PlanFrequency
    public let planDescription: String

    public init(id: String,
                name: String,
                shortName: String,
                planFrequency: PlanFrequency,
                planDescription: String) {
        self.id = id
        self.name = name
        self.shortName = shortName
        self.planFrequency = planFrequency
        self.planDescription = planDescription
    }

    public static func loadHardcodedPlan() -> LegacyWooPlan {
        LegacyWooPlan(id: AvailableInAppPurchasesWPComPlans.essentialMonthly.rawValue,
                name: Localization.essentialPlanName(frequency: .month),
                shortName: Localization.essentialPlanShortName,
                planFrequency: .month,
                planDescription: Localization.essentialPlanDescription)
    }

    public static func loadM2HardcodedPlans() -> [LegacyWooPlan] {
        [LegacyWooPlan(id: AvailableInAppPurchasesWPComPlans.essentialMonthly.rawValue,
                 name: Localization.essentialPlanName(frequency: .month),
                shortName: Localization.essentialPlanShortName,
                planFrequency: .month,
                planDescription: Localization.essentialPlanDescription),
        LegacyWooPlan(id: AvailableInAppPurchasesWPComPlans.essentialYearly.rawValue,
                name: Localization.essentialPlanName(frequency: .year),
                shortName: Localization.essentialPlanShortName,
                planFrequency: .year,
                planDescription: Localization.essentialPlanDescription),
        LegacyWooPlan(id: AvailableInAppPurchasesWPComPlans.performanceMonthly.rawValue,
                name: Localization.performancePlanName(frequency: .month),
                shortName: Localization.performancePlanShortName,
                planFrequency: .month,
                planDescription: Localization.performancePlanDescription),
        LegacyWooPlan(id: AvailableInAppPurchasesWPComPlans.performanceYearly.rawValue,
                name: Localization.performancePlanName(frequency: .year),
                shortName: Localization.performancePlanShortName,
                planFrequency: .year,
                planDescription: Localization.performancePlanDescription)]
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .planId)
        name = try container.decode(String.self, forKey: .planName)
        shortName = try container.decode(String.self, forKey: .planShortName)
        planFrequency = try container.decode(PlanFrequency.self, forKey: .planFrequency)
        planDescription = try container.decode(String.self, forKey: .planDescription)
    }

    private enum CodingKeys: String, CodingKey {
        case planId = "plan_id"
        case planName = "plan_name"
        case planShortName = "plan_short_name"
        case planFrequency = "plan_frequency"
        case planDescription = "plan_description"
    }

    public enum PlanFrequency: String, Decodable, Identifiable, CaseIterable {
        case month
        case year

        public var id: Self {
            return self
        }

        public var localizedString: String {
            switch self {
            case .month:
                return Localization.month
            case .year:
                return Localization.year
            }
        }

        private enum Localization {
            static let month = NSLocalizedString("per month", comment: "Description of the frequency of a monthly Woo plan")
            static let year = NSLocalizedString("per year", comment: "Description of the frequency of a yearly Woo plan")

            static let monthPlanName = NSLocalizedString("Monthly", comment: "Description of the frequency of a monthly Woo plan for use in the plan name")
            static let yearPlanName = NSLocalizedString("Yearly", comment: "Description of the frequency of a yearly Woo plan for use in the plan name")
        }

        public var localizedPlanName: String {
            switch self {
            case .month:
                return Localization.monthPlanName
            case .year:
                return Localization.yearPlanName
            }
        }
    }
}

public enum AvailableInAppPurchasesWPComPlans: String {
    case essentialMonthly = "woocommerce.express.essential.monthly"
    case essentialYearly = "woocommerce.express.essential.yearly"
    case performanceMonthly = "woocommerce.express.performance.monthly"
    case performanceYearly = "woocommerce.express.performance.yearly"
}

private extension LegacyWooPlan {
    enum Localization {
        static let essentialPlanNameFormat = NSLocalizedString(
            "Woo Express Essential %1$@",
            comment: "Title for the plan on a screen showing the Woo Express Essential plan upgrade benefits. " +
            "%1$@ will be replaced with Monthly or Yearly, and should be included in translations.")
        static func essentialPlanName(frequency: PlanFrequency) -> String {
            String.localizedStringWithFormat(essentialPlanNameFormat, frequency.localizedPlanName)
        }

        static let essentialPlanShortName = NSLocalizedString(
            "Essential",
            comment: "Short name for the plan on a screen showing the Woo Express Essential plan upgrade benefits")
        static let essentialPlanDescription = NSLocalizedString(
            "Everything you need to set up your store and start selling your products.",
            comment: "Description of the plan on a screen showing the Woo Express Essential plan upgrade benefits")

        static let performancePlanNameFormat = NSLocalizedString(
            "Woo Express Performance %1$@",
            comment: "Title for the plan on a screen showing the Woo Express Performance plan upgrade benefits " +
            "%1$@ will be replaced with Monthly or Yearly, and should be included in translations")
        static func performancePlanName(frequency: PlanFrequency) -> String {
            String.localizedStringWithFormat(performancePlanNameFormat, frequency.localizedPlanName)
        }
        static let performancePlanShortName = NSLocalizedString(
            "Performance",
            comment: "Short name for the plan on a screen showing the Woo Express Performance plan upgrade benefits")
        static let performancePlanDescription = NSLocalizedString(
            "Accelerate your growth with advanced features.",
            comment: "Description of the plan on a screen showing the Woo Express Performance plan upgrade benefits")
    }
}
