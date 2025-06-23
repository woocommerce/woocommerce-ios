import Foundation

public struct WooPlan: Decodable, Identifiable {
    public let id: String
    public let name: String
    public let shortName: String
    public let planFrequency: PlanFrequency
    public let planDescription: String
    public let planFeatures: [String]

    public init(id: String,
                name: String,
                shortName: String,
                planFrequency: PlanFrequency,
                planDescription: String,
                planFeatures: [String]) {
        self.id = id
        self.name = name
        self.shortName = shortName
        self.planFrequency = planFrequency
        self.planDescription = planDescription
        self.planFeatures = planFeatures
    }

    public var isEssential: Bool {
        Self.isEssential(id)
    }

    public static func isEssential(_ plan: String) -> Bool {
        let essentialMonthly = AvailableInAppPurchasesWPComPlans.essentialMonthly.rawValue
        let essentialYearly = AvailableInAppPurchasesWPComPlans.essentialYearly.rawValue

        if plan == essentialMonthly || plan == essentialYearly {
            return true
        } else {
            return false
        }
    }

    static func isYearly(_ planID: String) -> Bool {
        guard let plan = AvailableInAppPurchasesWPComPlans(rawValue: planID) else {
            return false
        }

        switch plan {
        case .essentialYearly, .performanceYearly:
            return true
        case .essentialMonthly, .performanceMonthly:
            return false
        }
    }

    public static func loadM2HardcodedPlans() -> [WooPlan] {
        [WooPlan(id: AvailableInAppPurchasesWPComPlans.essentialMonthly.rawValue,
                 name: Localization.essentialPlanName(frequency: .month),
                 shortName: Localization.essentialPlanShortName,
                 planFrequency: .month,
                 planDescription: Localization.essentialPlanDescription,
                 planFeatures: loadHardcodedPlanFeatures(AvailableInAppPurchasesWPComPlans.essentialMonthly.rawValue)),
         WooPlan(id: AvailableInAppPurchasesWPComPlans.essentialYearly.rawValue,
                 name: Localization.essentialPlanName(frequency: .year),
                 shortName: Localization.essentialPlanShortName,
                 planFrequency: .year,
                 planDescription: Localization.essentialPlanDescription,
                 planFeatures: loadHardcodedPlanFeatures(AvailableInAppPurchasesWPComPlans.essentialYearly.rawValue)),
         WooPlan(id: AvailableInAppPurchasesWPComPlans.performanceMonthly.rawValue,
                 name: Localization.performancePlanName(frequency: .month),
                 shortName: Localization.performancePlanShortName,
                 planFrequency: .month,
                 planDescription: Localization.performancePlanDescription,
                 planFeatures: loadHardcodedPlanFeatures(AvailableInAppPurchasesWPComPlans.performanceMonthly.rawValue)),
         WooPlan(id: AvailableInAppPurchasesWPComPlans.performanceYearly.rawValue,
                 name: Localization.performancePlanName(frequency: .year),
                 shortName: Localization.performancePlanShortName,
                 planFrequency: .year,
                 planDescription: Localization.performancePlanDescription,
                 planFeatures: loadHardcodedPlanFeatures(AvailableInAppPurchasesWPComPlans.performanceYearly.rawValue))]
    }

    private static func loadHardcodedPlanFeatures(_ planID: String) -> [String] {
        if isEssential(planID) {
            var planFeatures = isYearly(planID) ? [Localization.freeCustomDomainFeatureText] : []
            planFeatures += [
                Localization.supportFeatureText,
                Localization.unlimitedAdminsFeatureText,
                Localization.unlimitedProductsFeatureText,
                Localization.premiumThemesFeatureText,
                Localization.internationalSalesFeatureText,
                Localization.autoSalesTaxFeatureText,
                Localization.autoBackupsFeatureText,
                Localization.integratedShipmentFeatureText,
                Localization.analyticsDashboardFeatureText,
                Localization.giftVouchersFeatureText,
                Localization.emailMarketingFeatureText,
                Localization.marketplaceSyncFeatureText,
                Localization.advancedSEOFeatureText,
            ]
            return planFeatures
        } else {
            return [
                Localization.stockNotificationsFeatureText,
                Localization.marketingAutomationFeatureText,
                Localization.emailTriggersFeatureText,
                Localization.cartAbandonmentEmailsFeatureText,
                Localization.referralProgramsFeatureText,
                Localization.birthdayEmailsFeatureText,
                Localization.loyaltyProgramsFeatureText,
                Localization.bulkDiscountsFeatureText,
                Localization.addOnsFeatureText,
                Localization.assembledProductsFeatureText,
                Localization.orderQuantityFeatureText
            ]
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .planId)
        name = try container.decode(String.self, forKey: .planName)
        shortName = try container.decode(String.self, forKey: .planShortName)
        planFrequency = try container.decode(PlanFrequency.self, forKey: .planFrequency)
        planDescription = try container.decode(String.self, forKey: .planDescription)
        planFeatures = try container.decode([String].self, forKey: .planFeatures)
    }

    private enum CodingKeys: String, CodingKey {
        case planId = "plan_id"
        case planName = "plan_name"
        case planShortName = "plan_short_name"
        case planFrequency = "plan_frequency"
        case planDescription = "plan_description"
        case planFeatures = "plan_features"
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

private extension WooPlan {
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

        /// Plan features
        static let freeCustomDomainFeatureText = NSLocalizedString(
            "Free custom domain for 1 year",
            comment: "Description of one of the Essential plan features")

        static let supportFeatureText = NSLocalizedString(
            "Support via live chat and email",
            comment: "Description of one of the Essential plan features")

        static let unlimitedAdminsFeatureText = NSLocalizedString(
            "Unlimited admin accounts",
            comment: "Description of one of the Essential plan features")

        static let unlimitedProductsFeatureText = NSLocalizedString(
            "Create unlimited products",
            comment: "Description of one of the Essential plan features")

        static let premiumThemesFeatureText = NSLocalizedString(
            "Premium themes",
            comment: "Description of one of the Essential plan features")

        static let internationalSalesFeatureText = NSLocalizedString(
            "Sell internationally",
            comment: "Description of one of the Essential plan features")

        static let autoSalesTaxFeatureText = NSLocalizedString(
            "Automatic sales tax",
            comment: "Description of one of the Essential plan features")

        static let autoBackupsFeatureText = NSLocalizedString(
            "Automated backups and security scans",
            comment: "Description of one of the Essential plan features")

        static let integratedShipmentFeatureText = NSLocalizedString(
            "Integrated shipment tracking",
            comment: "Description of one of the Essential plan features")

        static let analyticsDashboardFeatureText = NSLocalizedString(
            "Analytics dashboard",
            comment: "Description of one of the Essential plan features")

        static let giftVouchersFeatureText = NSLocalizedString(
            "Sell and accept e-gift vouchers",
            comment: "Description of one of the Essential plan features")

        static let emailMarketingFeatureText = NSLocalizedString(
            "Email marketing built-in",
            comment: "Description of one of the Essential plan features")

        static let marketplaceSyncFeatureText = NSLocalizedString(
            "Marketplace sync and social media integrations",
            comment: "Description of one of the Essential plan features")

        static let advancedSEOFeatureText = NSLocalizedString(
            "Advanced SEO tools",
            comment: "Description of one of the Essential plan features")

        static let stockNotificationsFeatureText = NSLocalizedString(
            "Back in stock notifications",
            comment: "Description of one of the Performance plan features")

        static let marketingAutomationFeatureText = NSLocalizedString(
            "Marketing automation",
            comment: "Description of one of the Performance plan features")

        static let emailTriggersFeatureText = NSLocalizedString(
            "Automated email triggers",
            comment: "Description of one of the Performance plan features")

        static let cartAbandonmentEmailsFeatureText = NSLocalizedString(
            "Cart abandonment emails",
            comment: "Description of one of the Performance plan features")

        static let referralProgramsFeatureText = NSLocalizedString(
            "Referral programs",
            comment: "Description of one of the Performance plan features")

        static let birthdayEmailsFeatureText = NSLocalizedString(
            "Customer birthday emails",
            comment: "Description of one of the Performance plan features")

        static let loyaltyProgramsFeatureText = NSLocalizedString(
            "Loyalty points programs",
            comment: "Description of one of the Performance plan features")

        static let bulkDiscountsFeatureText = NSLocalizedString(
            "Offer bulk discounts",
            comment: "Description of one of the Performance plan features")

        static let addOnsFeatureText = NSLocalizedString(
            "Recommend add-ons",
            comment: "Description of one of the Performance plan features")

        static let assembledProductsFeatureText = NSLocalizedString(
            "Assembled products and kits",
            comment: "Description of one of the Performance plan features")

        static let orderQuantityFeatureText = NSLocalizedString(
            "Minimum/maximum order quantity",
            comment: "Description of one of the Performance plan features")
    }
}
