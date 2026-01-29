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
            comment: "This text appears as the title of a promotional banner card displayed on the dashboard/My Store screen, promoting the WooCommerce Point of Sale (POS) feature to encourage users to set it up on their tablet device."
        )

        static let cardMessage = NSLocalizedString(
            "posPromoOnPhonesCampaign.message",
            value: "Take in‑person payments with WooCommerce POS. Set up on a tablet and start selling today.",
            comment: "This text appears as the body message in a promotional banner on the dashboard that advertises WooCommerce POS functionality to encourage users to set up point-of-sale on tablets for in-person payments."
        )

        static let cardButtonTitle = NSLocalizedString(
            "posPromoOnPhonesCampaign.buttonTitle",
            value: "Learn more",
            comment: "This is the button text for a promotional banner on the app's dashboard that advertises WooCommerce POS for tablet usage. When tapped, the button leads users to more detailed information about setting up and using WooCommerce POS for in-person payments."
        )
    }
}
