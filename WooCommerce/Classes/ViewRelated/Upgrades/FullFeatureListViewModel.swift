import Foundation
import SwiftUI

struct FullFeatureListGroups {
    public let title: String
    public let essentialFeatures: [String]
    public let performanceFeatures: [String]
}

struct FullFeatureListViewModel {
    static func hardcodedFullFeatureList() -> [FullFeatureListGroups] {
        return [
            FullFeatureListGroups(title: Localization.yourStoreFeatureTitle,
                                  essentialFeatures: [
                                    Localization.wooCommerceStoreText,
                                    Localization.wooCommerceMobileAppText,
                                    Localization.wordPressCMSText,
                                    Localization.wordPressMobileAppText,
                                    Localization.freeSSLCertificateText,
                                    Localization.generousStorageText,
                                    Localization.automatedBackupQuickRestoreText,
                                    Localization.adFreeExperienceText,
                                    Localization.unlimitedAdminAccountsText,
                                    Localization.liveChatSupportText,
                                    Localization.emailSupportText,
                                    Localization.premiumThemesIncludedText,
                                    Localization.salesReportsText,
                                    Localization.googleAnalyticsText,
                                  ],
                                  performanceFeatures: []
                                 ),
            FullFeatureListGroups(title: Localization.productsFeatureTitle,
                                  essentialFeatures: [
                                    Localization.listUnlimitedProducts,
                                    Localization.giftCards,
                                    Localization.listProductsByBrand,
                                  ],
                                  performanceFeatures: [
                                    Localization.minMaxOrderQuantityText,
                                    Localization.productBundlesText,
                                    Localization.customProductKitsText,
                                    Localization.productRecommendationsText,
                                  ]),
            FullFeatureListGroups(title: Localization.paymentsFeatureTitle,
                                  essentialFeatures: [
                                    Localization.integratedPayments,
                                    Localization.internationalPayments,
                                    Localization.automatedSalesTaxes,
                                    Localization.acceptLocalPayments,
                                    Localization.recurringPayments,
                                  ],
                                  performanceFeatures: []),

            FullFeatureListGroups(title: Localization.marketingAndEmailFeatureTitle,
                                  essentialFeatures: [
                                    Localization.promoteOnTikTok,
                                    Localization.syncWithPinterest,
                                    Localization.connectWithFacebook,
                                    Localization.advancedSeoTools,
                                    Localization.advertiseOnGoogle,
                                    Localization.customOrderEmails,
                                  ],
                                  performanceFeatures: [
                                    Localization.backInStockEmailsText,
                                    Localization.marketingAutomationText,
                                    Localization.abandonedCartRecoveryText,
                                    Localization.referralProgramsText,
                                    Localization.customerBirthdayEmailsText,
                                    Localization.loyaltyPointsProgramsText,
                                  ]),

            FullFeatureListGroups(title: Localization.shippingFeatureTitle,
                                  essentialFeatures: [
                                    Localization.shipmentTracking,
                                    Localization.liveShippingRates,
                                    Localization.printShippingLabels
                                    ],
                                  performanceFeatures: [
                                    Localization.discountedShippingText,
                                  ]),
        ]
    }
}

private extension FullFeatureListViewModel {
    struct Localization {
        static let yourStoreFeatureTitle = NSLocalizedString(
            "Your Store",
            comment: "The title of one of the feature groups offered with paid plans")

        static let productsFeatureTitle = NSLocalizedString(
            "Products",
            comment: "The title of one of the feature groups offered with paid plans")

        static let paymentsFeatureTitle = NSLocalizedString(
            "Payments",
            comment: "The title of one of the feature groups offered with paid plans")

        static let marketingAndEmailFeatureTitle = NSLocalizedString(
            "Marketing & Email",
            comment: "The title of one of the feature groups offered with paid plans")

        static let shippingFeatureTitle = NSLocalizedString(
            "Shipping",
            comment: "The title of one of the feature groups offered with paid plans")

        static let wooCommerceStoreText = NSLocalizedString(
            "WooCommerce store",
            comment: "The title of one of the features offered with the Essential plan")

        static let wooCommerceMobileAppText = NSLocalizedString(
            "WooCommerce mobile app",
            comment: "The title of one of the features offered with the Essential plan")

        static let wordPressCMSText = NSLocalizedString(
            "WordPress CMS",
            comment: "The title of one of the features offered with the Essential plan")

        static let wordPressMobileAppText = NSLocalizedString(
            "WordPress mobile app",
            comment: "The title of one of the features offered with the Essential plan")

        static let freeSSLCertificateText = NSLocalizedString(
            "Free SSL certificate",
            comment: "The title of one of the features offered with the Essential plan")

        static let generousStorageText = NSLocalizedString(
            "Generous storage",
            comment: "The title of one of the features offered with the Essential plan")

        static let automatedBackupQuickRestoreText = NSLocalizedString(
            "Automated backup + quick restore",
            comment: "The title of one of the features offered with the Essential plan")

        static let adFreeExperienceText = NSLocalizedString(
            "Ad-free experience",
            comment: "The title of one of the features offered with the Essential plan")

        static let unlimitedAdminAccountsText = NSLocalizedString(
            "Unlimited admin accounts",
            comment: "The title of one of the features offered with the Essential plan")

        static let liveChatSupportText = NSLocalizedString(
            "Live chat support",
            comment: "The title of one of the features offered with the Essential plan")

        static let emailSupportText = NSLocalizedString(
            "Email support",
            comment: "The title of one of the features offered with the Essential plan")

        static let premiumThemesIncludedText = NSLocalizedString(
            "Premium themes included",
            comment: "The title of one of the features offered with the Essential plan")

        static let salesReportsText = NSLocalizedString(
            "Sales reports",
            comment: "The title of one of the features offered with the Essential plan")

        static let googleAnalyticsText = NSLocalizedString(
            "Google Analytics",
            comment: "The title of one of the features offered with the Essential plan")

        static let listUnlimitedProducts = NSLocalizedString(
            "List unlimited products",
            comment: "The title of one of the features offered with the Essential plan")

        static let giftCards = NSLocalizedString(
            "Gift cards",
            comment: "The title of one of the features offered with the Essential plan")

        static let listProductsByBrand = NSLocalizedString(
            "List products by brand",
            comment: "The title of one of the features offered with the Essential plan")

        static let integratedPayments = NSLocalizedString(
            "Integrated payments",
            comment: "The title of one of the features offered with the Essential plan")

        static let internationalPayments = NSLocalizedString(
            "International payments'",
            comment: "The title of one of the features offered with the Essential plan")

        static let automatedSalesTaxes = NSLocalizedString(
            "Automated sales taxes",
            comment: "The title of one of the features offered with the Essential plan")

        static let acceptLocalPayments = NSLocalizedString(
            "Accept local payments'",
            comment: "The title of one of the features offered with the Essential plan")

        static let recurringPayments = NSLocalizedString(
            "Recurring payments'",
            comment: "The title of one of the features offered with the Essential plan")
        static let promoteOnTikTok = NSLocalizedString(
            "Promote on TikTok",
            comment: "The title of one of the features offered with the Essential plan")

        static let syncWithPinterest = NSLocalizedString(
            "Sync with Pinterest",
            comment: "The title of one of the features offered with the Essential plan")

        static let connectWithFacebook = NSLocalizedString(
            "Connect with Facebook",
            comment: "The title of one of the features offered with the Essential plan")

        static let advancedSeoTools = NSLocalizedString(
            "Advanced SEO tools",
            comment: "The title of one of the features offered with the Essential plan")

        static let advertiseOnGoogle = NSLocalizedString(
            "Advertise on Google",
            comment: "The title of one of the features offered with the Essential plan")

        static let customOrderEmails = NSLocalizedString(
            "Custom order emails",
            comment: "The title of one of the features offered with the Essential plan")

        static let shipmentTracking = NSLocalizedString(
            "Shipment tracking",
            comment: "The title of one of the features offered with the Essential plan")

        static let liveShippingRates = NSLocalizedString(
            "Live shipping rates",
            comment: "The title of one of the features offered with the Essential plan")

        static let printShippingLabels = NSLocalizedString(
            "Print shipping labels²",
            comment: "The title of one of the features offered with the Essential plan")

        static let minMaxOrderQuantityText = NSLocalizedString(
            "Min/Max order quantity",
            comment: "The title of one of the features offered with the Performance plan")

        static let productBundlesText = NSLocalizedString(
            "Product Bundles",
            comment: "The title of one of the features offered with the Performance plan")

        static let customProductKitsText = NSLocalizedString(
            "Custom product kits",
            comment: "The title of one of the features offered with the Performance plan")

        static let productRecommendationsText = NSLocalizedString(
            "Product recommendations",
            comment: "The title of one of the features offered with the Performance plan")

        static let backInStockEmailsText = NSLocalizedString(
            "Back in stock emails",
            comment: "The title of one of the features offered with the Performance plan")

        static let marketingAutomationText = NSLocalizedString(
            "Marketing automation",
            comment: "The title of one of the features offered with the Performance plan")

        static let abandonedCartRecoveryText = NSLocalizedString(
            "Abandoned cart recovery",
            comment: "The title of one of the features offered with the Performance plan")

        static let referralProgramsText = NSLocalizedString(
            "Referral programs",
            comment: "The title of one of the features offered with the Performance plan")

        static let customerBirthdayEmailsText = NSLocalizedString(
            "Customer birthday emails",
            comment: "The title of one of the features offered with the Performance plan")

        static let loyaltyPointsProgramsText = NSLocalizedString(
            "Loyalty points programs",
            comment: "The title of one of the features offered with the Performance plan")

        static let discountedShippingText = NSLocalizedString(
            "Discounted shipping²",
            comment: "The title of one of the features offered with the Performance plan")
    }
}
