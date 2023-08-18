import Foundation

public struct WooPlan: Identifiable {
    public let id: String
    public let planFeatures: [String]

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

    public static func loadHardcodedPlan(_ selectedPlanID: String) -> WooPlan {
        if isEssential(selectedPlanID) {
            var planFeatures = isYearly(selectedPlanID) ? [Localization.freeCustomDomainFeatureText] : []
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
            return WooPlan(id: selectedPlanID,
                           planFeatures: planFeatures)
        } else {
            return WooPlan(id: selectedPlanID,
                           planFeatures: [
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
                           ])
        }
    }
}

private extension WooPlan {
    enum Localization {
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
