import Foundation

struct LinkedProductsPromoCampaign {

    var configuration: FeatureAnnouncementCardViewModel.Configuration {
        .init(source: .productDetail,
              campaign: .linkedProductsPromo,
              title: Localization.cardTitle,
              message: Localization.cardMessage,
              buttonTitle: Localization.cardButtonTitle,
              image: .paymentsFeatureBannerImage,
              showDismissConfirmation: false,
              dismissAlertTitle: "",
              dismissAlertMessage: "",
              showDividers: true)
    }
}

extension LinkedProductsPromoCampaign {
    enum Localization {
        static let cardTitle = NSLocalizedString("Boost your sales with linked products", comment: "Title for the Linked Products announcement banner")

        static let cardMessage = NSLocalizedString(
            "Give your customers helpful and relevant product recommendations by adding upsells and cross-sells.",
            comment: "Message for the Linked Products announcement banner")

        static let cardButtonTitle = NSLocalizedString(
            "Try it now",
            comment: "Title for the button on the Linked Products announcement banner")
    }
}
