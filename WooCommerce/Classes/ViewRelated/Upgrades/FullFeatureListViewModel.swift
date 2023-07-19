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
    static let featureGroupTitleComment = "The title of one of the feature groups offered with paid plans"
    static let essentialFeatureTitleComment = "The title of one of the features offered with the Essential plan"
    static let performanceFeatureTitleComment = "The title of one of the features offered with the Performance plan"

    struct Localization {
        static let yourStoreFeatureTitle = NSLocalizedString(
            "Your Store",
            comment: featureGroupTitleComment)

        static let productsFeatureTitle = NSLocalizedString(
            "Products",
            comment: featureGroupTitleComment)

        static let paymentsFeatureTitle = NSLocalizedString(
            "Payments",
            comment: featureGroupTitleComment)

        static let marketingAndEmailFeatureTitle = NSLocalizedString(
            "Marketing & Email",
            comment: featureGroupTitleComment)

        static let shippingFeatureTitle = NSLocalizedString(
            "Shipping",
            comment: featureGroupTitleComment)

        static let wooCommerceStoreText = NSLocalizedString(
            "WooCommerce store",
            comment: essentialFeatureTitleComment)

        static let wooCommerceMobileAppText = NSLocalizedString(
            "WooCommerce mobile app",
            comment: essentialFeatureTitleComment)

        static let wordPressCMSText = NSLocalizedString(
            "WordPress CMS",
            comment: essentialFeatureTitleComment)

        static let wordPressMobileAppText = NSLocalizedString(
            "WordPress mobile app",
            comment: essentialFeatureTitleComment)

        static let freeSSLCertificateText = NSLocalizedString(
            "Free SSL certificate",
            comment: essentialFeatureTitleComment)

        static let generousStorageText = NSLocalizedString(
            "Generous storage",
            comment: essentialFeatureTitleComment)

        static let automatedBackupQuickRestoreText = NSLocalizedString(
            "Automated backup + quick restore",
            comment: essentialFeatureTitleComment)

        static let adFreeExperienceText = NSLocalizedString(
            "Ad-free experience",
            comment: essentialFeatureTitleComment)

        static let unlimitedAdminAccountsText = NSLocalizedString(
            "Unlimited admin accounts",
            comment: essentialFeatureTitleComment)

        static let liveChatSupportText = NSLocalizedString(
            "Live chat support",
            comment: essentialFeatureTitleComment)

        static let emailSupportText = NSLocalizedString(
            "Email support",
            comment: essentialFeatureTitleComment)

        static let premiumThemesIncludedText = NSLocalizedString(
            "Premium themes included",
            comment: essentialFeatureTitleComment)

        static let salesReportsText = NSLocalizedString(
            "Sales reports",
            comment: essentialFeatureTitleComment)

        static let googleAnalyticsText = NSLocalizedString(
            "Google Analytics",
            comment: essentialFeatureTitleComment)

        static let listUnlimitedProducts = NSLocalizedString(
            "List unlimited products",
            comment: essentialFeatureTitleComment)

        static let giftCards = NSLocalizedString(
            "Gift cards",
            comment: essentialFeatureTitleComment)

        static let listProductsByBrand = NSLocalizedString(
            "List products by brand",
            comment: essentialFeatureTitleComment)

        static let integratedPayments = NSLocalizedString(
            "Integrated payments",
            comment: essentialFeatureTitleComment)

        static let internationalPayments = NSLocalizedString(
            "International payments'",
            comment: essentialFeatureTitleComment)

        static let automatedSalesTaxes = NSLocalizedString(
            "Automated sales taxes",
            comment: essentialFeatureTitleComment)

        static let acceptLocalPayments = NSLocalizedString(
            "Accept local payments'",
            comment: essentialFeatureTitleComment)

        static let recurringPayments = NSLocalizedString(
            "Recurring payments'",
            comment: essentialFeatureTitleComment)

        static let promoteOnTikTok = NSLocalizedString(
            "Promote on TikTok",
            comment: essentialFeatureTitleComment)

        static let syncWithPinterest = NSLocalizedString(
            "Sync with Pinterest",
            comment: essentialFeatureTitleComment)

        static let connectWithFacebook = NSLocalizedString(
            "Connect with Facebook",
            comment: essentialFeatureTitleComment)

        static let advancedSeoTools = NSLocalizedString(
            "Advanced SEO tools",
            comment: essentialFeatureTitleComment)

        static let advertiseOnGoogle = NSLocalizedString(
            "Advertise on Google",
            comment: essentialFeatureTitleComment)

        static let customOrderEmails = NSLocalizedString(
            "Custom order emails",
            comment: essentialFeatureTitleComment)

        static let shipmentTracking = NSLocalizedString(
            "Shipment tracking",
            comment: essentialFeatureTitleComment)

        static let liveShippingRates = NSLocalizedString(
            "Live shipping rates",
            comment: essentialFeatureTitleComment)

        static let printShippingLabels = NSLocalizedString(
            "Print shipping labels²",
            comment: essentialFeatureTitleComment)

        static let minMaxOrderQuantityText = NSLocalizedString(
            "Min/Max order quantity",
            comment: performanceFeatureTitleComment)

        static let productBundlesText = NSLocalizedString(
            "Product Bundles",
            comment: performanceFeatureTitleComment)

        static let customProductKitsText = NSLocalizedString(
            "Custom product kits",
            comment: performanceFeatureTitleComment)

        static let productRecommendationsText = NSLocalizedString(
            "Product recommendations",
            comment: performanceFeatureTitleComment)

        static let backInStockEmailsText = NSLocalizedString(
            "Back in stock emails",
            comment: performanceFeatureTitleComment)

        static let marketingAutomationText = NSLocalizedString(
            "Marketing automation",
            comment: performanceFeatureTitleComment)

        static let abandonedCartRecoveryText = NSLocalizedString(
            "Abandoned cart recovery",
            comment: performanceFeatureTitleComment)

        static let referralProgramsText = NSLocalizedString(
            "Referral programs",
            comment: performanceFeatureTitleComment)

        static let customerBirthdayEmailsText = NSLocalizedString(
            "Customer birthday emails",
            comment: performanceFeatureTitleComment)

        static let loyaltyPointsProgramsText = NSLocalizedString(
            "Loyalty points programs",
            comment: performanceFeatureTitleComment)

        static let discountedShippingText = NSLocalizedString(
            "Discounted shipping²",
            comment: performanceFeatureTitleComment)
    }
}
