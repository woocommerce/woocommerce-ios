import Foundation
import SwiftUI

public struct WooPlan: Identifiable {
    public let id: String
    public let name: String
    public let shortName: String
    public let planDescription: String
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

    public static func loadHardcodedPlan(_ selectedPlanID: String) -> WooPlan {

        if isEssential(selectedPlanID) {
            return WooPlan(id: "",
                           name: "Essential",
                           shortName: "",
                           planDescription: "Everything you need to set up your store and start selling your products.",
                           planFeatures: [
                            "Free custom domain for 1 year",
                            "Support via live chat and email",
                            "Unlimited admin accounts",
                            "Create unlimited products",
                            "Premium themes",
                            "Sell internationally",
                            "Automatic sales tax",
                            "Automated backups and security scans",
                            "Integrated shipment tracking",
                            "Analytics dashboard",
                            "Sell and accept e-gift vouchers",
                            "Email marketing built-in",
                            "Marketplace sync and social media integrations",
                            "Advanced SEO tools"
                           ])
        } else {
            return WooPlan(id: "",
                           name: "Performance",
                           shortName: "",
                           planDescription: "Accelerate your growth with advanced features.",
                           planFeatures: [
                            "Back in stock notifications",
                            "Marketing automation",
                            "Automated email triggers",
                            "Cart abandonment emails",
                            "Referral programs",
                            "Customer birthday emails",
                            "Loyalty points programs",
                            "Offer bulk discounts",
                            "Recommend add-ons",
                            "Assembled products and kits",
                            "Minimum/maximum order quantity"
                           ])
        }
    }
}

public struct LegacyWooPlan: Decodable {
    public let id: String
    public let name: String
    public let shortName: String
    public let planFrequency: PlanFrequency
    public let planDescription: String
    public let headerImageFileName: String
    public let headerImageCardColor: Color
    public let planFeatureGroups: [WooPlanFeatureGroup]

    public init(id: String,
                name: String,
                shortName: String,
                planFrequency: PlanFrequency,
                planDescription: String,
                headerImageFileName: String,
                headerImageCardColor: Color,
                planFeatureGroups: [WooPlanFeatureGroup]) {
        self.id = id
        self.name = name
        self.shortName = shortName
        self.planFrequency = planFrequency
        self.planDescription = planDescription
        self.headerImageFileName = headerImageFileName
        self.headerImageCardColor = headerImageCardColor
        self.planFeatureGroups = planFeatureGroups
    }

    public static func loadHardcodedPlan() -> LegacyWooPlan {
        LegacyWooPlan(id: AvailableInAppPurchasesWPComPlans.essentialMonthly.rawValue,
                name: Localization.essentialPlanName(frequency: .month),
                shortName: Localization.essentialPlanShortName,
                planFrequency: .month,
                planDescription: Localization.essentialPlanDescription,
                headerImageFileName: "express-essential-header",
                headerImageCardColor: (try? Color(rgbString: "rgba(238, 226, 211, 1)")) ?? .white,
                planFeatureGroups: hardcodedFeatureGroups())
    }

    public static func loadM2HardcodedPlans() -> [LegacyWooPlan] {
        [LegacyWooPlan(id: AvailableInAppPurchasesWPComPlans.essentialMonthly.rawValue,
                 name: Localization.essentialPlanName(frequency: .month),
                shortName: Localization.essentialPlanShortName,
                planFrequency: .month,
                planDescription: Localization.essentialPlanDescription,
                headerImageFileName: "express-essential-header",
                headerImageCardColor: (try? Color(rgbString: "rgba(238, 226, 211, 1)")) ?? .white,
                planFeatureGroups: hardcodedFeatureGroups()),
        LegacyWooPlan(id: AvailableInAppPurchasesWPComPlans.essentialYearly.rawValue,
                name: Localization.essentialPlanName(frequency: .year),
                shortName: Localization.essentialPlanShortName,
                planFrequency: .year,
                planDescription: Localization.essentialPlanDescription,
                headerImageFileName: "express-essential-header",
                headerImageCardColor: (try? Color(rgbString: "rgba(238, 226, 211, 1)")) ?? .white,
                planFeatureGroups: hardcodedFeatureGroups()),
        LegacyWooPlan(id: AvailableInAppPurchasesWPComPlans.performanceMonthly.rawValue,
                name: Localization.performancePlanName(frequency: .month),
                shortName: Localization.performancePlanShortName,
                planFrequency: .month,
                planDescription: Localization.performancePlanDescription,
                headerImageFileName: "express-essential-header",
                headerImageCardColor: (try? Color(rgbString: "rgba(238, 226, 211, 1)")) ?? .white,
                planFeatureGroups: []),
        LegacyWooPlan(id: AvailableInAppPurchasesWPComPlans.performanceYearly.rawValue,
                name: Localization.performancePlanName(frequency: .year),
                shortName: Localization.performancePlanShortName,
                planFrequency: .year,
                planDescription: Localization.performancePlanDescription,
                headerImageFileName: "express-essential-header",
                headerImageCardColor: (try? Color(rgbString: "rgba(238, 226, 211, 1)")) ?? .white,
                planFeatureGroups: [])]
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .planId)
        name = try container.decode(String.self, forKey: .planName)
        shortName = try container.decode(String.self, forKey: .planShortName)
        planFrequency = try container.decode(PlanFrequency.self, forKey: .planFrequency)
        planDescription = try container.decode(String.self, forKey: .planDescription)
        headerImageFileName = try container.decode(String.self, forKey: .headerImageFileName)
        let headerImageCardColorRGBString = try container.decode(String.self, forKey: .headerImageCardColor)
        headerImageCardColor = try Color(rgbString: headerImageCardColorRGBString)
        planFeatureGroups = try container.decode([WooPlanFeatureGroup].self, forKey: .planFeatureGroups)
    }

    private enum CodingKeys: String, CodingKey {
        case planId = "plan_id"
        case planName = "plan_name"
        case planShortName = "plan_short_name"
        case planFrequency = "plan_frequency"
        case planDescription = "plan_description"
        case headerImageFileName = "header_image_filename"
        case headerImageCardColor = "header_image_card_color"
        case planFeatureGroups = "feature_categories"
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
    case essentialYearly = "debug.woocommerce.express.essential.yearly"
    case performanceMonthly = "debug.woocommerce.express.performance.monthly"
    case performanceYearly = "debug.woocommerce.express.performance.yearly"
}

private extension LegacyWooPlan {
    static func hardcodedFeatureGroups() -> [WooPlanFeatureGroup] {
        [
            WooPlanFeatureGroup(
                title: Localization.generalFeaturesTitle,
                description: Localization.generalFeaturesDescription,
                imageFilename: "express-plans-homepage",
                imageCardColor: (try? Color(rgbString: "rgba(240, 246, 252, 1)")) ?? .white,
                features: [
                    WooPlanFeature(
                        title: Localization.onlineStoreTitle,
                        description: Localization.onlineStoreDescription
                    ),
                    WooPlanFeature(
                        title: Localization.mobileAppTitle,
                        description: Localization.mobileAppDescription
                    ),
                    WooPlanFeature(
                        title: Localization.supportTitle,
                        description: Localization.supportDescription
                    ),
                    WooPlanFeature(
                        title: Localization.unlimitedStaffAccountsTitle,
                        description: Localization.unlimitedStaffAccountsDescription
                    )
                ]
            ),
            WooPlanFeatureGroup(
                title: Localization.paymentsTitle,
                description: Localization.paymentsDescription,
                imageFilename: "express-plans-card-payment-webpage",
                imageCardColor: (try? Color(rgbString: "rgba(247, 237, 247, 1)")) ?? .white,
                features: [
                    WooPlanFeature(
                        title: Localization.creditCardRateTitle,
                        description: Localization.creditCardRateDescription
                    ),
                    WooPlanFeature(
                        title: Localization.sellInCurrenciesTitle,
                        description: Localization.sellInCurrenciesDescription
                    ),
                    WooPlanFeature(
                        title: Localization.advancedSubscriptionsTitle,
                        description: Localization.advancedSubscriptionsDescription
                    ),
                    WooPlanFeature(
                        title: Localization.preOrdersTitle,
                        description: Localization.preOrdersDescription
                    ),
                    WooPlanFeature(
                        title: Localization.stripeM2ReaderTitle,
                        description: Localization.stripeM2ReaderDescription
                    ),
                    WooPlanFeature(
                        title: Localization.tapToPayOniPhoneTitle,
                        description: Localization.tapToPayOniPhoneDescription
                    )
                ]
            ),
            WooPlanFeatureGroup(
                title: Localization.productManagementTitle,
                description: Localization.productManagementDescription,
                imageFilename: "express-plans-two-product-webpages",
                imageCardColor: (try? Color(rgbString: "rgba(228, 242, 237, 1)")) ?? .white,
                features: [
                    WooPlanFeature(
                        title: Localization.unlimitedProductsTitle,
                        description: Localization.unlimitedProductsDescription
                    ),
                    WooPlanFeature(
                        title: Localization.offerGiftCardsTitle,
                        description: Localization.offerGiftCardsDescription
                    ),
                    WooPlanFeature(
                        title: Localization.sendBackInStockNotificationsTitle,
                        description: Localization.sendBackInStockNotificationsDescription
                    ),
                    WooPlanFeature(
                        title: Localization.setOrderLimitsTitle,
                        description: Localization.setOrderLimitsDescription
                    ),
                    WooPlanFeature(
                        title: Localization.offerCustomizableProductKitsTitle,
                        description: Localization.offerCustomizableProductKitsDescription
                    ),
                    WooPlanFeature(
                        title: Localization.importProductsViaCSVTitle,
                        description: Localization.importProductsViaCSVDescription
                    ),
                    WooPlanFeature(
                        title: Localization.sellProductAddOnsTitle,
                        description: Localization.sellProductAddOnsDescription
                    ),
                    WooPlanFeature(
                        title: Localization.unlimitedImagesTitle,
                        description: Localization.unlimitedImagesDescription
                    ),
                    WooPlanFeature(
                        title: Localization.productRecommendationsTitle,
                        description: Localization.productRecommendationsDescription
                    )
                ]
            ),
            WooPlanFeatureGroup(
                title: Localization.themesAndCustomizationTitle,
                description: Localization.themesAndCustomizationDescription,
                imageFilename: "express-plans-design-colors-typography",
                imageCardColor: (try? Color(rgbString: "rgba(233, 239, 245, 1)")) ?? .white,
                features: [
                    WooPlanFeature(
                        title: Localization.premiumThemesTitle,
                        description: Localization.premiumThemesDescription
                    ),
                    WooPlanFeature(
                        title: Localization.blockBasedTemplatesTitle,
                        description: Localization.blockBasedTemplatesDescription
                    ),
                    WooPlanFeature(
                        title: Localization.cartAndCheckoutOptimizationTitle,
                        description: Localization.cartAndCheckoutOptimizationDescription
                    )
                ]
            ),
            WooPlanFeatureGroup(
                title: Localization.marketingAndConversionTitle,
                description: Localization.marketingAndConversionDescription,
                imageFilename: "express-plans-webpage-in-envelope",
                imageCardColor: (try? Color(rgbString: "rgba(249, 241, 249, 1)")) ?? .white,
                features: [
                    WooPlanFeature(
                        title: Localization.syncWithSocialChannelsTitle,
                        description: Localization.syncWithSocialChannelsDescription
                    ),
                    WooPlanFeature(
                        title: Localization.advertiseWithGoogleTitle,
                        description: Localization.advertiseWithGoogleDescription
                    ),
                    WooPlanFeature(
                        title: Localization.recoverAbandonedCartsTitle,
                        description: Localization.recoverAbandonedCartsDescription
                    ),
                    WooPlanFeature(
                        title: Localization.encourageReferralsTitle,
                        description: Localization.encourageReferralsDescription
                    ),
                    WooPlanFeature(
                        title: Localization.sendBirthdayCouponsTitle,
                        description: Localization.sendBirthdayCouponsDescription
                    ),
                    WooPlanFeature(
                        title: Localization.driveLoyaltyTitle,
                        description: Localization.driveLoyaltyDescription
                    )
                ]
            ),
            WooPlanFeatureGroup(
                title: Localization.shippingTitle,
                description: Localization.shippingDescription,
                imageFilename: "express-plans-shipping-manifest",
                imageCardColor: (try? Color(rgbString: "rgba(255, 233, 204, 1)")) ?? .white,
                features: [
                    WooPlanFeature(
                        title: Localization.shippingLabelsTitle,
                        description: Localization.shippingLabelsDescription
                    ),
                    WooPlanFeature(
                        title: Localization.shippingTrackingTitle,
                        description: Localization.shippingTrackingDescription
                    ),
                    WooPlanFeature(
                        title: Localization.shippingRatesTitle,
                        description: Localization.shippingRatesDescription
                    ),
                    WooPlanFeature(
                        title: Localization.conditionalShippingAndPaymentsTitle,
                        description: Localization.conditionalShippingAndPaymentsDescription
                    ),
                    WooPlanFeature(
                        title: Localization.returnsAndWarrantyTitle,
                        description: Localization.returnsAndWarrantyDescription
                    )
                ]
            )
        ]
    }

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


        /// General features
        static let generalFeaturesTitle = NSLocalizedString(
            "General features",
            comment: "Title for the screen showing the general features of the Woo Express Essential Monthly plan " +
            "upgrade benefits")
        static let generalFeaturesDescription = NSLocalizedString(
            "Everything you need to grow your business.",
            comment: "Description for the link to the screen showing the general features of the Woo Express " +
            "Essential Monthly plan upgrade benefits")

        static let onlineStoreTitle = NSLocalizedString(
            "Online store",
            comment: "Title of a feature of a Woo Express Essential plan shown in a row in a table of benefits")
        static let onlineStoreDescription = NSLocalizedString(
            "All-in-one solution for starting your ecommerce store.",
            comment: "Description of a feature of a Woo Express Essential plan shown in a row in a table of benefits")

        static let mobileAppTitle = NSLocalizedString(
            "Mobile app",
            comment: "Title of a feature of a Woo Express Essential plan shown in a row in a table of benefits")
        static let mobileAppDescription = NSLocalizedString(
            "Manage your store on the go with the Woo Mobile App.",
            comment: "Description of a feature of a Woo Express Essential plan shown in a row in a table of benefits")

        static let supportTitle = NSLocalizedString(
            "24/7 support",
            comment: "Title of a feature of a Woo Express Essential plan shown in a row in a table of benefits")
        static let supportDescription = NSLocalizedString(
            "Need help? Reach out to us anytime, anywhere. Get 24/7 support via live chat and email.",
            comment: "Description of a feature of a Woo Express Essential plan shown in a row in a table of benefits")

        static let unlimitedStaffAccountsTitle = NSLocalizedString(
            "Unlimited staff accounts",
            comment: "Title of a feature of a Woo Express Essential plan shown in a row in a table of benefits")
        static let unlimitedStaffAccountsDescription = NSLocalizedString(
            "Let your colleagues work on the site with you.",
            comment: "Description of a feature of a Woo Express Essential plan shown in a row in a table of benefits")

        /// Payments
        static let paymentsTitle = NSLocalizedString(
            "Payments",
            comment: "Title for the screen showing the payments features of the Woo Express Essential Monthly plan " +
            "upgrade benefits")
        static let paymentsDescription = NSLocalizedString(
            "Quickly and easily accept payments.",
            comment: "Description for the link to the screen showing the payments features of the Woo Express " +
            "Essential Monthly plan upgrade benefits")

        static let creditCardRateTitle = NSLocalizedString(
            "Credit card rate: 2.9% + 30¢",
            comment: "Title of a feature of a Woo Express Essential plan shown in a row in a table of benefits")
        static let creditCardRateDescription = NSLocalizedString(
            "Accept Visa, Mastercard and all other major payment methods.",
            comment: "Description of a feature of a Woo Express Essential plan shown in a row in a table of benefits")

        static let sellInCurrenciesTitle = NSLocalizedString(
            "Sell in over 100 currencies",
            comment: "Title of a feature of a Woo Express Essential plan shown in a row in a table of benefits")
        static let sellInCurrenciesDescription = NSLocalizedString(
            "Meet your buyers where they are: accepts payments in 135+ currencies, no other extensions needed.",
            comment: "Description of a feature of a Woo Express Essential plan shown in a row in a table of benefits")

        static let advancedSubscriptionsTitle = NSLocalizedString(
            "Advanced subscriptions",
            comment: "Title of a feature of a Woo Express Essential plan shown in a row in a table of benefits")
        static let advancedSubscriptionsDescription = NSLocalizedString(
            "Let customers subscribe to your products or services and pay on a weekly, monthly or annual basis.",
            comment: "Description of a feature of a Woo Express Essential plan shown in a row in a table of benefits")

        static let preOrdersTitle = NSLocalizedString(
            "Pre-orders",
            comment: "Title of a feature of a Woo Express Essential plan shown in a row in a table of benefits")
        static let preOrdersDescription = NSLocalizedString(
            "Allow customers to order products before they are available.",
            comment: "Description of a feature of a Woo Express Essential plan shown in a row in a table of benefits")

        static let stripeM2ReaderTitle = NSLocalizedString(
            "Stripe M2 Reader",
            comment: "Title of a feature of a Woo Express Essential plan shown in a row in a table of benefits")
        static let stripeM2ReaderDescription = NSLocalizedString(
            "Easy-to-use mobile card reader designed for fast, reliable in-person payments, including contactless, " +
            "swipe, and chip. (Additional purchase required.)",
            comment: "Description of a feature of a Woo Express Essential plan shown in a row in a table of benefits")

        static let tapToPayOniPhoneTitle = NSLocalizedString(
            "Tap to Pay on iPhone",
            comment: "Title of a feature of a Woo Express Essential plan shown in a row in a table of benefits")
        static let tapToPayOniPhoneDescription = NSLocalizedString(
            "Take contactless payments on an iPhone XS or newer, no additional hardware needed.",
            comment: "Description of a feature of a Woo Express Essential plan shown in a row in a table of benefits")

        /// Product management
        static let productManagementTitle = NSLocalizedString(
            "Product management",
            comment: "Title for the screen showing the product management features of the Woo Express Essential " +
            "Monthly plan upgrade benefits")
        static let productManagementDescription = NSLocalizedString(
            "Simplify the way you manage, sell and promote your products.",
            comment: "Description for the link to the screen showing the product management features of the Woo Express " +
            "Essential Monthly plan upgrade benefits")

        static let unlimitedProductsTitle = NSLocalizedString(
            "Unlimited products",
            comment: "Title of a feature of a Woo Express Essential plan shown in a row in a table of benefits")
        static let unlimitedProductsDescription = NSLocalizedString(
            "Add unlimited products to your store.",
            comment: "Description of a feature of a Woo Express Essential plan shown in a row in a table of benefits")

        static let offerGiftCardsTitle = NSLocalizedString(
            "Offer gift cards",
            comment: "Title of a feature of a Woo Express Essential plan shown in a row in a table of benefits")
        static let offerGiftCardsDescription = NSLocalizedString(
            "Sell and accept pre-paid, multi-purpose e-gift vouchers.",
            comment: "Description of a feature of a Woo Express Essential plan shown in a row in a table of benefits")

        static let sendBackInStockNotificationsTitle = NSLocalizedString(
            "Send back in stock notifications",
            comment: "Title of a feature of a Woo Express Essential plan shown in a row in a table of benefits")
        static let sendBackInStockNotificationsDescription = NSLocalizedString(
            "Notify customers when your products are restocked.",
            comment: "Description of a feature of a Woo Express Essential plan shown in a row in a table of benefits")

        static let setOrderLimitsTitle = NSLocalizedString(
            "Set order limits",
            comment: "Title of a feature of a Woo Express Essential plan shown in a row in a table of benefits")
        static let setOrderLimitsDescription = NSLocalizedString(
            "Specify min and max allowed product quantities for orders.",
            comment: "Description of a feature of a Woo Express Essential plan shown in a row in a table of benefits")

        static let offerCustomizableProductKitsTitle = NSLocalizedString(
            "Offer customizable product kits",
            comment: "Title of a feature of a Woo Express Essential plan shown in a row in a table of benefits")
        static let offerCustomizableProductKitsDescription = NSLocalizedString(
            "Use Composite Products to add product kit building functionality with inventory management.",
            comment: "Description of a feature of a Woo Express Essential plan shown in a row in a table of benefits")

        static let importProductsViaCSVTitle = NSLocalizedString(
            "Import your products via CSV",
            comment: "Title of a feature of a Woo Express Essential plan shown in a row in a table of benefits")
        static let importProductsViaCSVDescription = NSLocalizedString(
            "Import, merge, and export products using a CSV file.",
            comment: "Description of a feature of a Woo Express Essential plan shown in a row in a table of benefits")

        static let sellProductAddOnsTitle = NSLocalizedString(
            "Sell product add-ons",
            comment: "Title of a feature of a Woo Express Essential plan shown in a row in a table of benefits")
        static let sellProductAddOnsDescription = NSLocalizedString(
            "Enable gift wrapping messages or custom pricing.",
            comment: "Description of a feature of a Woo Express Essential plan shown in a row in a table of benefits")

        static let unlimitedImagesTitle = NSLocalizedString(
            "Unlimited images",
            comment: "Title of a feature of a Woo Express Essential plan shown in a row in a table of benefits")
        static let unlimitedImagesDescription = NSLocalizedString(
            "Add any number of images to your products.",
            comment: "Description of a feature of a Woo Express Essential plan shown in a row in a table of benefits")

        static let productRecommendationsTitle = NSLocalizedString(
            "Product recommendations",
            comment: "Title of a feature of a Woo Express Essential plan shown in a row in a table of benefits")
        static let productRecommendationsDescription = NSLocalizedString(
            "Earn more revenue with automated upsell and cross-sell product recommendations.",
            comment: "Description of a feature of a Woo Express Essential plan shown in a row in a table of benefits")

        /// Themes and customization
        static let themesAndCustomizationTitle = NSLocalizedString(
            "Themes and customization",
            comment: "Title for the screen showing the customization features of the Woo Express Essential Monthly plan " +
            "upgrade benefits")
        static let themesAndCustomizationDescription = NSLocalizedString(
            "Simplify the way you manage, sell and promote your products.",
            comment: "Description for the link to the screen showing the customization features of the Woo Express " +
            "Essential Monthly plan upgrade benefits")

        static let premiumThemesTitle = NSLocalizedString(
            "Premium themes",
            comment: "Title of a feature of a Woo Express Essential plan shown in a row in a table of benefits")
        static let premiumThemesDescription = NSLocalizedString(
            "Tap into a diverse selection of beautifully designed premium themes.",
            comment: "Description of a feature of a Woo Express Essential plan shown in a row in a table of benefits")

        static let blockBasedTemplatesTitle = NSLocalizedString(
            "Block-based templates",
            comment: "Title of a feature of a Woo Express Essential plan shown in a row in a table of benefits")
        static let blockBasedTemplatesDescription = NSLocalizedString(
            "Take control over your store's layout without touching a line of code.",
            comment: "Description of a feature of a Woo Express Essential plan shown in a row in a table of benefits")

        static let cartAndCheckoutOptimizationTitle = NSLocalizedString(
            "Cart and checkout optimization",
            comment: "Title of a feature of a Woo Express Essential plan shown in a row in a table of benefits")
        static let cartAndCheckoutOptimizationDescription = NSLocalizedString(
            "Streamline your checkout and boost conversions with the Cart and Checkout blocks.",
            comment: "Description of a feature of a Woo Express Essential plan shown in a row in a table of benefits")

        /// Marketing and Conversion
        static let marketingAndConversionTitle = NSLocalizedString(
            "Marketing and conversion",
            comment: "Title for the screen showing the marketing features of the Woo Express Essential Monthly plan " +
            "upgrade benefits")
        static let marketingAndConversionDescription = NSLocalizedString(
            "Grow your sales with built-in marketing and conversion tools.",
            comment: "Description for the link to the screen showing the marketing features of the Woo Express " +
            "Essential Monthly plan upgrade benefits")

        static let syncWithSocialChannelsTitle = NSLocalizedString(
            "Sync with social channels",
            comment: "Title of a feature of a Woo Express Essential plan shown in a row in a table of benefits")
        static let syncWithSocialChannelsDescription = NSLocalizedString(
            "Promote your products across popular social media platforms, including Facebook, Pinterest, and TikTok.",
            comment: "Description of a feature of a Woo Express Essential plan shown in a row in a table of benefits")

        static let advertiseWithGoogleTitle = NSLocalizedString(
            "Advertise with Google",
            comment: "Title of a feature of a Woo Express Essential plan shown in a row in a table of benefits")
        static let advertiseWithGoogleDescription = NSLocalizedString(
            "Create and manage ads promoting your products to Google users, straight from your dashboard.",
            comment: "Description of a feature of a Woo Express Essential plan shown in a row in a table of benefits")

        static let recoverAbandonedCartsTitle = NSLocalizedString(
            "Recover abandoned carts",
            comment: "Title of a feature of a Woo Express Essential plan shown in a row in a table of benefits")
        static let recoverAbandonedCartsDescription = NSLocalizedString(
            "Drive more sales by automatically emailing customers who leave your store without checking out.",
            comment: "Description of a feature of a Woo Express Essential plan shown in a row in a table of benefits")

        static let encourageReferralsTitle = NSLocalizedString(
            "Encourage referrals",
            comment: "Title of a feature of a Woo Express Essential plan shown in a row in a table of benefits")
        static let encourageReferralsDescription = NSLocalizedString(
            "Offer free gifts or coupons when your customers refer new shoppers.",
            comment: "Description of a feature of a Woo Express Essential plan shown in a row in a table of benefits")

        static let sendBirthdayCouponsTitle = NSLocalizedString(
            "Send birthday coupons",
            comment: "Title of a feature of a Woo Express Essential plan shown in a row in a table of benefits")
        static let sendBirthdayCouponsDescription = NSLocalizedString(
            "Automatically email our customers a birthday discount to keep them coming back.",
            comment: "Description of a feature of a Woo Express Essential plan shown in a row in a table of benefits")

        static let driveLoyaltyTitle = NSLocalizedString(
            "Drive loyalty",
            comment: "Title of a feature of a Woo Express Essential plan shown in a row in a table of benefits")
        static let driveLoyaltyDescription = NSLocalizedString(
            "Keep your loyal customers loyal with a rewards program",
            comment: "Description of a feature of a Woo Express Essential plan shown in a row in a table of benefits")

        /// Shipping
        static let shippingTitle = NSLocalizedString(
            "Shipping",
            comment: "Title for the screen showing the shipping features of the Woo Express Essential Monthly plan " +
            "upgrade benefits")
        static let shippingDescription = NSLocalizedString(
            "Grow your sales with built-in marketing and conversion tools.",
            comment: "Description for the link to the screen showing the shipping features of the Woo Express " +
            "Essential Monthly plan upgrade benefits")

        static let shippingLabelsTitle = NSLocalizedString(
            "Shipping labels",
            comment: "Title of a feature of a Woo Express Essential plan shown in a row in a table of benefits")
        static let shippingLabelsDescription = NSLocalizedString(
            "Save on shipping by printing labels right from your store.",
            comment: "Description of a feature of a Woo Express Essential plan shown in a row in a table of benefits")

        static let shippingTrackingTitle = NSLocalizedString(
            "Shipping tracking",
            comment: "Title of a feature of a Woo Express Essential plan shown in a row in a table of benefits")
        static let shippingTrackingDescription = NSLocalizedString(
            "Provide customers with an easy way to track their shipment.",
            comment: "Description of a feature of a Woo Express Essential plan shown in a row in a table of benefits")

        static let shippingRatesTitle = NSLocalizedString(
            "Shipping rates",
            comment: "Title of a feature of a Woo Express Essential plan shown in a row in a table of benefits")
        static let shippingRatesDescription = NSLocalizedString(
            "Define multiple shipping rates based on location, price, weight, or other criteria.",
            comment: "Description of a feature of a Woo Express Essential plan shown in a row in a table of benefits")

        static let conditionalShippingAndPaymentsTitle = NSLocalizedString(
            "Conditional shipping and payments",
            comment: "Title of a feature of a Woo Express Essential plan shown in a row in a table of benefits")
        static let conditionalShippingAndPaymentsDescription = NSLocalizedString(
            "Use conditional logic to restrict the shipping and payment options.",
            comment: "Description of a feature of a Woo Express Essential plan shown in a row in a table of benefits")

        static let returnsAndWarrantyTitle = NSLocalizedString(
            "Returns and warranty",
            comment: "Title of a feature of a Woo Express Essential plan shown in a row in a table of benefits")
        static let returnsAndWarrantyDescription = NSLocalizedString(
            "Manage the RMA process, add warranties to products and let customers request/manage returns from their account.",
            comment: "Description of a feature of a Woo Express Essential plan shown in a row in a table of benefits")
    }
}
