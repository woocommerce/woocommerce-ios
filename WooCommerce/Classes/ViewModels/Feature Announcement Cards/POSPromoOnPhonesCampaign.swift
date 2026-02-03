import Foundation

struct POSPromoOnPhonesCampaign {

    /// The base URL for the CTA (without UTM params)
    static var ctaURLString: String {
        WooConstants.URLs.posLearnMore.rawValue
    }

    var configuration: FeatureAnnouncementCardViewModel.Configuration {
        .init(source: .myStore,
              campaign: .posPromoOnPhones,
              title: Localization.cardTitle,
              message: Localization.cardMessage,
              buttonTitle: Localization.cardButtonTitle,
              image: .posOnPhonesPromotionBannerCorner,
              imageUrl: nil,
              imageDarkUrl: nil,
              showDismissConfirmation: false,
              dismissAlertTitle: "",
              dismissAlertMessage: "",
              showDividers: false,
              badgeType: nil)
    }
}

extension POSPromoOnPhonesCampaign {
    enum Localization {
        static let cardTitle = NSLocalizedString(
            "posPromoOnPhonesCampaign.title",
            value: "Run WooCommerce POS on your tablet",
            comment: "Title for the POS promotional banner on the dashboard"
        )

        static let cardMessage = NSLocalizedString(
            "posPromoOnPhonesCampaign.message",
            value: "Take in‑person payments with WooCommerce POS. Set up on a tablet and start selling today.",
            comment: "Message for the POS promotional banner on the dashboard"
        )

        static let cardButtonTitle = NSLocalizedString(
            "posPromoOnPhonesCampaign.buttonTitle",
            value: "Learn more",
            comment: "Button title for the POS promotional banner on the dashboard"
        )
    }
}
