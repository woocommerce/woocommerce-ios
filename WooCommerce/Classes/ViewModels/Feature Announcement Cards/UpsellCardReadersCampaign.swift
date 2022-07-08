import Foundation

struct UpsellCardReadersCampaign {
    let source: WooAnalyticsEvent.FeatureCard.Source

    var configuration: FeatureAnnouncementCardViewModel.Configuration {
        .init(source: source,
              campaign: .upsellCardReaders,
              title: Localization.cardTitle,
              message: Localization.cardMessage,
              buttonTitle: Localization.cardButtonTitle,
              image: .paymentsFeatureBannerImage)
    }
}

extension UpsellCardReadersCampaign {
    enum Localization {
        static let cardTitle = NSLocalizedString("Accept payments easily",
                    comment: "Title for the feature announcement banner intended to upsell card readers")

        static let cardMessage = NSLocalizedString("Get ready to accept payments with a card reader.",
                    comment: "Message for the feature announcement banner intended to upsell card readers")

        static let cardButtonTitle = NSLocalizedString("Purchase Card Reader",
                    comment: "Title for the button on the feature announcement banner intended to upsell card readers")
    }
}
