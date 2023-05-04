import Foundation
import WooFoundation

struct UpsellCardReadersCampaign {
    let source: WooAnalyticsEvent.FeatureCard.Source

    private var buttonTitle: String? {
        switch source {
        case .paymentMethods, .orderList:
            return Localization.cardButtonTitle
        case .settings:
            return nil
        default:
            return nil
        }
    }

    var configuration: FeatureAnnouncementCardViewModel.Configuration {
        .init(source: source,
              campaign: .upsellCardReaders,
              title: Localization.cardTitle,
              message: Localization.cardMessage,
              buttonTitle: buttonTitle,
              image: .paymentsFeatureBannerImage,
              imageUrl: nil,
              imageDarkUrl: nil,
              showDismissConfirmation: true,
              dismissAlertTitle: Localization.dismissTitle,
              dismissAlertMessage: Localization.dismissMessage,
              showDividers: false,
              badgeType: .new)
    }
}

extension UpsellCardReadersCampaign {
    enum Localization {
        static let cardTitle = NSLocalizedString(
            "Accept payments easily",
            comment: "Title for the feature announcement banner intended to upsell card readers")

        static let cardMessage = NSLocalizedString(
            "Get ready to accept payments with a card reader.",
            comment: "Message for the feature announcement banner intended to upsell card readers")

        static let cardButtonTitle = NSLocalizedString(
            "Purchase card reader",
            comment: "Title for the button on the feature announcement banner intended to upsell card readers")

        static let dismissTitle = NSLocalizedString(
            "In-Person Payments",
            comment: "Title for a dismissal alert on the upsell card reader feature announcement banner")

        static let dismissMessage = NSLocalizedString(
            "No worries! You can always get started with In-Person Payments in Settings",
            comment: "Message for a dismissal alert on the upsell card reader feature announcement banner")

        static let cardReaderWebViewTitle = NSLocalizedString(
            "Purchase Card Reader",
            comment: "Title for the WebView opened to upsell card readers")
    }
}

extension UpsellCardReadersCampaign {
    var utmProvider: WooCommerceComUTMProvider {
        WooCommerceComUTMProvider(
            campaign: Constants.utmCampaign,
            source: source.rawValue,
            content: configuration.campaign.rawValue,
            siteID: ServiceLocator.stores.sessionManager.defaultStoreID)
    }
}

private enum Constants {
    static let utmCampaign = "feature_announcement_card"
}
